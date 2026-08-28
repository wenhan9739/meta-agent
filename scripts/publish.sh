#!/usr/bin/env bash
# ============================================================
# Meta-Agent 本地发布脚本：本地 --push--> GitHub（唯一基准）
# 与服务器端 deploy/sync.sh（GitHub --pull--> 服务器）构成闭环。
#
# 用法（仓库根目录；建议 Git Bash / WSL / Linux / macOS）：
#   scripts/publish.sh                  # 校验干净 → push main → push tag v0.1
#   scripts/publish.sh --no-server      # push 后不 SSH 触发服务器
#   scripts/publish.sh --force-tag      # 标签已存在且移动时强制覆盖远程 tag
#
# 环境变量：
#   META_SYNC_HOST   可选；设置后 push 完成即 SSH 触发服务器 deploy/sync.sh
#                    例: META_SYNC_HOST=root@124.223.213.90
# ============================================================
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"

BRANCH="main"
TAG="v0.1"
TRIGGER=1
FORCE_TAG=0
for arg in "$@"; do
  case "$arg" in
    --no-server|--no-trigger) TRIGGER=0 ;;
    --force-tag) FORCE_TAG=1 ;;
  esac
done
if [ -n "${1:-}" ] && [ "${1#v}" != "$1" ]; then TAG="$1"; fi

ORIGIN="$(git remote get-url origin)"
echo "== 本地发布：${BRANCH} -> GitHub 唯一基准 (${ORIGIN})"

echo "== [1/5] fetch origin --tags"
git fetch origin --tags --prune

echo "== [2/5] 校验分支与干净度"
[ "$(git branch --show-current)" = "$BRANCH" ] || { echo "error: 不在 ${BRANCH} 分支"; exit 1; }
[ -z "$(git status --porcelain)" ] || { echo "error: 工作区未提交，先 commit 再发布"; git status --short; exit 1; }

echo "== [3/5] 同步落后提交（fast-forward）"
BEHIND=$(git rev-list --count HEAD..origin/${BRANCH} 2>/dev/null || echo 0)
if [ "$BEHIND" -gt 0 ]; then
  git pull --ff-only origin "${BRANCH}"
fi

echo "== [4/5] push ${BRANCH} -> origin"
git push origin "${BRANCH}"

echo "== [5/5] push tag ${TAG} -> origin"
if git rev-parse "refs/tags/${TAG}" >/dev/null 2>&1; then
  if [ "$FORCE_TAG" = "1" ]; then git push origin "${TAG}" --force; else git push origin "${TAG}"; fi
else
  echo "  (本地无 ${TAG} 标签，跳过)"
fi

echo
echo "== 发布完成。服务器端请执行：deploy/sync.sh"
if [ "$TRIGGER" = "1" ] && [ -n "${META_SYNC_HOST:-}" ]; then
  echo "== 触发服务器同步：${META_SYNC_HOST}"
  ssh "${META_SYNC_HOST}" "cd /opt/meta-agent && deploy/sync.sh"
elif [ "$TRIGGER" = "1" ]; then
  echo "== 未设置 META_SYNC_HOST，跳过服务器触发。"
fi
