#!/usr/bin/env bash
# ============================================================
# Meta-Agent 三端同步脚本（服务器端）
# 架构：GitHub/origin = 唯一事实源；本地 = 镜像；服务器 = 部署 + gitignored 私有配置。
# 本脚本让服务器与 origin 指定版本完全一致，并保持 git 工作区干净
# （生产 Caddyfile/API Key 走 gitignored 的 Caddyfile.prod 与 .env）。
#
# 用法（在仓库根目录）：
#   deploy/sync.sh                 # 同步到 origin/main（当前管理版本）
#   deploy/sync.sh v0.1            # 同步到指定 tag/commit
#   deploy/sync.sh --fast          # 仅覆盖 workspace（薄层镜像，复用已装 R 包，快）
#   deploy/sync.sh v0.1 --fast
# ============================================================
set -euo pipefail

# 自更新安全：把本脚本复制到 /tmp 再执行，避免 git reset 覆盖正在运行的脚本本身。
if [ "${META_SYNC_RUN:-}" != "1" ]; then
  COPY="$(mktemp /tmp/meta-sync.XXXXXX.sh)"
  cp "$0" "$COPY"
  chmod +x "$COPY"
  exec env META_SYNC_RUN=1 bash "$COPY" "$@"
fi

REF="main"
FAST=0
for arg in "$@"; do
  case "$arg" in
    --fast) FAST=1 ;;
    *) REF="$arg" ;;
  esac
done

cd "$(dirname "$0")/.."
echo "==> [1/5] fetch & checkout origin/${REF}"
git fetch origin --tags --prune
git reset --hard "origin/${REF}"

echo "==> [2/5] refresh deploy/workspace"
cd deploy
rm -rf workspace && mkdir -p workspace
cp ../AGENTS.md workspace/
cp -r ../.dsh workspace/.dsh
cp -r ../templates workspace/templates

echo "==> [3/5] ensure prod config present"
[ -f Caddyfile.prod ] || { echo "缺少 deploy/Caddyfile.prod，请从 Caddyfile.prod.example 拷贝并填入真实域名/密码哈希"; exit 1; }
[ -f .env ] || { echo "缺少 deploy/.env"; exit 1; }

echo "==> [4/5] build + up ($([ "$FAST" = 1 ] && echo fast-thin || echo full))"
if [ "$FAST" = "1" ]; then
  cat > Dockerfile.overlay <<'EOF'
FROM meta-agent:latest
COPY --chown=metauser:metauser workspace/ /home/metauser/agent/
EOF
  docker build -t meta-agent:current -f Dockerfile.overlay .
  docker tag meta-agent:current meta-agent:latest
  rm -f Dockerfile.overlay
  docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
else
  docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build
fi

echo "==> [5/5] verify"
for i in $(seq 1 12); do
  ST=$(docker ps --filter name=deploy-agent-alice-1 --format '{{.Status}}')
  echo "  health: ${ST}"
  echo "$ST" | grep -q healthy && break
  sleep 8
done
docker ps --format '{{.Names}} {{.Status}} {{.Image}}'
