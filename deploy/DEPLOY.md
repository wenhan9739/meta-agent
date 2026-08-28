# Meta-Agent 云端商业化部署指南

## 架构总览

```
用户浏览器
   │ HTTPS (wss:// 流式)
   ▼
Caddy 网关 (TLS自动证书 + 认证 + 按用户路由)
   │ 内网
   ▼
per-user meta-agent 容器 (dsh web + R + metafor + 技能包)
   │ 出站 HTTPS
   ▼
DeepSeek 官方 API (服务端统一 Key, 统一计费)
```

### 为什么这样设计（关键安全/商业决策）

| 决策 | 理由 |
|------|------|
| 每用户一容器 | dsh 无多租户认证；会话/文件/凭证天然隔离；单用户 R 崩溃不互相影响 |
| 容器内只绑 127.0.0.1 + socat 出容器 | dsh 明确拒绝 0.0.0.0（防 RCE）；边界由网关控制 |
| 网关做认证，容器不管认证 | dsh 的 trust fence 源码注释明确"not authentication"；特权 API（改配置/读凭证）钉死 loopback，网关用户碰不到服务端配置 → 计费 Key 不可被客户读取或替换 |
| 服务端统一注入 DEEPSEEK_API_KEY | 商业计费可控；客户无需自备 Key；用量可按容器日志审计 |
| 项目产出 volume 持久化 | 用户数据（projects/）独立卷，备份/导出/销毁清晰 |



## 版本与三端同步（v0.1）

### 唯一事实源

- **GitHub `origin/main`** 是唯一事实源；Git 标签 `v0.1` 是发布基线。
- **本地开发机** = `origin/main` 的克隆/镜像（`D:\work\meta agent`）。
- **服务器** = `origin/main` 的克隆 + 部署私有配置（不入库）。

### 仓库 vs 部署私有配置边界

| 内容 | 归宿 | 说明 |
|---|---|---|
| AGENTS.md / `.dsh/skills` / `templates` / `deploy/` 源码 / `VERSION` | Git 仓库，三端一致 | 一切实现 |
| `deploy/Caddyfile.prod` | 仅服务器，`.gitignore` 忽略 | 真实域名 + 每用户 Basic Auth 密码哈希 |
| `deploy/.env` | 仅服务器，`.gitignore` 忽略 | `DEEPSEEK_API_KEY`、`TRUSTED_HOST` |
| `deploy/workspace/`、`deploy/*.tgz` | 运行时/构建产物，`.gitignore` 忽略 | 不提交、不同步 |

### 发布与同步闭环（GitHub 唯一基准）

```
  本地(开发)         GitHub(唯一基准)         服务器(部署)
  develop --push-->  origin/main(=v0.1)  --pull--> /opt/meta-agent
  scripts/publish.sh                        deploy/sync.sh
```

```sh
# ① 本地：开发、提交后推送到 GitHub（唯一基准）
scripts/publish.sh                 # 校验干净 → push main → push tag v0.1
#   可加 --no-server；或 META_SYNC_HOST=root@host 让推送后自动触发服务器

# ② 服务器：从 GitHub 拉齐并重建/重启（保持 git 干净）
cd /opt/meta-agent
deploy/sync.sh --check             # 只报告漂移，不改动
deploy/sync.sh                     # 同步到 origin/main（GitHub）
deploy/sync.sh v0.1                # 同步到稳定 tag
deploy/sync.sh --fast             # 仅覆盖 workspace（薄层镜像，复用已装 R 包）
deploy/sync.sh --no-fetch --fast   # 离线 bundle 场景
```

`sync.sh` 组合 `docker-compose.yml` + `docker-compose.prod.yml`：后者把网关挂载路径换成 `Caddyfile.prod`，该文件已被 `.gitignore` 忽略，因此服务器 git 工作区始终干净，与本地/GitHub 完全一致。

### 演进纪律

- 三端**实现**（Git 树）必须逐字节一致；`VERSION` 文件是版本锚点。
- 新增用户：改 `Caddyfile.prod` + `docker-compose.yml` 复制 agent 服务块 + 重跑 `sync.sh`。
- 升级依赖/改 Dockerfile：用 `deploy/sync.sh`（全量 `--build`；R 包层缓存 miss 会重新安装，耗时较长）。

## 快速开始（单机，1 个域名）

### 前置
- 一台云主机（2C4G 起步，建议 4C8G 因 R 分析吃内存）
- Docker + Docker Compose v2
- 一个域名（如 `meta.example.com`），A 记录指到主机 IP

### 步骤

1. **准备镜像内容**（在开发机 `D:\work\meta agent\`）：
   ```sh
   cd deploy
   # 打包工作区到镜像上下文
   mkdir -p workspace
   cp ../AGENTS.md workspace/
   cp -r ../.dsh workspace/.dsh
   cp -r ../templates workspace/templates
   # projects/ 不进镜像（用户数据运行时产生）
   docker build -t meta-agent:latest .
   ```

2. **配置密钥**：
   ```sh
   echo "DEEPSEEK_API_KEY=sk-你的官方Key" > .env
   chmod 600 .env
   ```

3. **生成 Basic Auth 密码哈希**（替换 Caddyfile 里的占位）：
   ```sh
   docker run --rm caddy:2-alpine caddy hash-password
   # 按提示输入密码, 把输出填入 Caddyfile 的 alice 行
   ```

4. **改 Caddyfile 域名**：把 `alice.meta.example.com` 全部替换为你的域名。

5. **启动**：
   ```sh
   docker compose up -d
   docker compose logs -f gateway   # 看证书签发
   ```

6. **验证**：浏览器访问 `https://alice.meta.example.com`，Basic Auth 登录后：
   - 模型按钮应显示 DeepSeek-V4-Flash
   - 发"做一个 xx 的 meta 分析"测试立项流程
   - 测试 R：让 agent 跑 `templates/R/01_run_meta.R` 冒烟测试

## 新用户接入（扩容流程）

1. `docker-compose.yml` 复制一个 agent 服务块（新名字、新 volume）
2. `Caddyfile` 加对应子域路由
3. `docker compose up -d` 滚动生效
4. 用户数 >10 后建议：迁移到 K8s（Deployment per user）或用
   [Coolify/Dokploy](https://coolify.io) 类面板自动化"加用户=加容器"

## 运维要点

| 事项 | 做法 |
|------|------|
| 备份 | `docker run --rm -v agent_alice_work:/data busybox tar czf - /data > backup_alice.tar.gz`（projects 数据）|
| 升级 agent | 改 workspace → 重建镜像 → `docker compose up -d --build`（volume 数据不丢）|
| 用量审计 | 容器日志 `docker compose logs agent-alice`；正式计费建议接 DeepSeek 用量后台对账 |
| 限流 | Caddy `rate_limit` 插件或网关层加；防单用户刷爆 Key |
| 安全更新 | `docker compose build --pull && docker compose up -d`（每月）|
| 首屏性能 | Caddy 已对 `/assets/*`、`/plugins/*` 开启 `gzip/zstd` + `immutable` 长缓存；改 Caddy 后只需 `docker restart deploy-gateway-1`，**无需重建 agent/R 层**（避免 4G 服务器 OOM）|

## 商业化合规清单（上线前自查）

- [ ] 用户协议：明确 AI 生成内容需研究者自行核实；不承诺发表成功
- [ ] 免责声明：分析结果仅供研究参考，不构成医疗建议
- [ ] 数据隐私：用户项目数据（可能含未发表数据）的存储地/保留期/删除流程写进隐私政策
- [ ] AI 披露：agent 默认在稿件中加 AI 辅助声明（期刊政策差异大，用户可关）
- [ ] API Key 轮换流程文档化（泄露应急）
- [ ] 掠夺性期刊黑名单内置在 meta-journal 技能中（已做）

## 已知限制与后续路线

1. **dsh 预览版**：官方声明会有 breaking changes；锁版本部署（`DSH_VERSION` build arg），升级前在 staging 容器回归测试九阶段流程
2. **认证升级**：Basic Auth → OIDC（Authentik 自建 / Auth0）支持注册/付费墙
3. **计费系统**：按容器数包月起步；按 token 计费需自建网关计量（Caddy access log + DeepSeek 用量 API 对账）
4. **并发 R 任务**：单容器串行；重度用户可加 `dsh` 的 job 队列或独立 R 计算容器（plumber API）
5. **文献全文获取**：云端无机构订阅，全文下载依赖用户上传或 OA 渠道（技能已按此设计）
