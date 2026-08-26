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
# TRUSTED_HOST: 允许外部网关 Host 通过 /api trust fence (如 magpieagent.online)
# 不加则只有 localhost 能调 API (经网关远程访问会全 403)
TRUSTED_ARGS=""
for h in ${TRUSTED_HOST:-}; do
  TRUSTED_ARGS="$TRUSTED_ARGS --trusted-host $h"
done
dsh web --no-open --port 3080 $TRUSTED_ARGS &
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
