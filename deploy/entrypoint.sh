#!/bin/bash
# Meta-Agent 容器入口
# 1. 启动 dsh web (绑 127.0.0.1:3080)
# 2. socat 把 0.0.0.0:8080 转发到 127.0.0.1:3080 (容器边界)
# 认证由外层网关 (Caddy forward_auth) 负责, 容器本身不暴露公网

set -e

export DSH_HOME="${DSH_HOME:-/home/metauser/.dsh}"
mkdir -p "$DSH_HOME"

# API Key 检查 (启动环境变量, credentials-local 直接读取)
if [ -z "$DEEPSEEK_API_KEY" ]; then
  echo "[entrypoint] WARNING: DEEPSEEK_API_KEY not set; model calls will fail" >&2
fi

# dsh web 后台启动
# MAGPIE UI: seed/patch the web profile manifest so the white-label
# bundle is part of dsh.profile.bundles (idempotent; no pnpm needed).
MAGPIE_PKG="$DSH_HOME/profiles/web/package.json"
mkdir -p "$(dirname "$MAGPIE_PKG")"
if [ ! -f "$MAGPIE_PKG" ]; then
  cat > "$MAGPIE_PKG" <<'JSON'
{
  "name": "dsh-profile-web",
  "private": true,
  "dependencies": {},
  "dsh": {
    "profile": {
      "bundles": [
        "@deepseek-ai/dsh-base",
        "@deepseek-ai/dsh-web-app",
        "@magpie/meta-agent-ui"
      ]
    }
  }
}
JSON
  echo "[entrypoint] web profile seeded (magpie ui included)"
else
  node -e 'const fs=require("fs");const p=process.argv[1];const j=JSON.parse(fs.readFileSync(p,"utf8"));j.dsh=j.dsh||{};j.dsh.profile=j.dsh.profile||{};const b=j.dsh.profile.bundles||[];if(!b.includes("@magpie/meta-agent-ui")){b.push("@magpie/meta-agent-ui");j.dsh.profile.bundles=b;fs.writeFileSync(p,JSON.stringify(j,null,2)+"\n");console.log("[entrypoint] magpie ui bundle added to web profile");}else{console.log("[entrypoint] magpie ui bundle present");}' "$MAGPIE_PKG"
fi

dsh web --no-open --port 3080 &
DSH_PID=$!

# 等待就绪
for i in $(seq 1 30); do
  if curl -sf http://127.0.0.1:3080 -o /dev/null; then
    echo "[entrypoint] dsh web ready on 127.0.0.1:3080"
    break
  fi
  [ "$i" = "30" ] && { echo "[entrypoint] dsh failed to start" >&2; exit 1; }
  sleep 2
done

# 0.0.0.0:8080 -> 127.0.0.1:3080
socat TCP-LISTEN:8080,fork,reuseaddr TCP:127.0.0.1:3080 &
SOCAT_PID=$!

trap "kill $DSH_PID $SOCAT_PID 2>/dev/null" TERM INT
echo "[entrypoint] serving on 0.0.0.0:8080 (gateway -> here)"
wait -n
exit $?
