# Meta-Agent 云端商业化镜像
# 基于 node:24 + R 运行时 + dsh CLI + meta-agent 工作区
# 构建: docker build -t meta-agent:latest .
# 运行: 见 docker-compose.yml

FROM node:24-bookworm-slim

ARG DSH_VERSION=latest
ENV DEBIAN_FRONTEND=noninteractive
ENV NODE_ENV=production

# ---------- 系统依赖 ----------
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg python3 python3-pip \
    r-base r-base-dev libcurl4-openssl-dev libssl-dev libxml2-dev \
    pandoc \
    && rm -rf /var/lib/apt/lists/*

# ---------- R 包（meta 分析全家桶，预装保证开箱即用） ----------
RUN Rscript -e ' \
  options(warn=1); \
  cran <- "https://cloud.r-project.org"; \
  install.packages(c("metafor","meta","netmeta","forestplot","ggplot2", \
                     "dplyr","tidyr","readr","readxl","jsonlite","yaml", \
                     "rmarkdown","knitr"), repos=cran, Ncpus=2); \
  ' && rm -rf /tmp/downloaded_packages /tmp/Rtmp*

# ---------- dsh CLI ----------
RUN npm install -g @deepseek-ai/dsh@${DSH_VERSION}

# ---------- 非 root 运行用户 ----------
RUN useradd -m -s /bin/bash metauser
USER metauser
WORKDIR /home/metauser

# ---------- Meta-Agent 工作区（AGENTS.md + skills + templates + R 脚本） ----------
COPY --chown=metauser:metauser workspace/ /home/metauser/agent/

# 容器内 Rscript 路径探测由 AGENTS.md 的"先探测再使用"规则处理:
# Linux 容器内为 /usr/bin/Rscript

# ---------- 凭证与配置由运行时注入（不在镜像内） ----------
# DEEPSEEK_API_KEY 通过环境变量注入 (docker-compose secrets/env_file)
# dsh 的 credentials-local 会读取启动环境变量, 无需写文件

# ---------- 端口与启动 ----------
# dsh web 只绑 127.0.0.1 (安全设计), 由 sidecar/网关反代
# 容器内用 supervisor 或直接 socat 转发 0.0.0.0:8080 -> 127.0.0.1:3080
USER root
RUN apt-get update && apt-get install -y --no-install-recommends socat \
    && rm -rf /var/lib/apt/lists/*
USER metauser

COPY --chown=metauser:metauser entrypoint.sh /home/metauser/entrypoint.sh
RUN chmod +x /home/metauser/entrypoint.sh

EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=40s \
  CMD curl -sf http://127.0.0.1:3080 -o /dev/null || exit 1

ENTRYPOINT ["/home/metauser/entrypoint.sh"]
