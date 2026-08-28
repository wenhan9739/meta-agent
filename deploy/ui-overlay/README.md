# 证据科学探索者 UI 白标插件（@magpie/meta-agent-ui）

在 DeepSeek Harness Web 客户端上实现“证据科学探索者”品牌白标（蓝翼渐变 logo
+ “你好 · 证据科学探索者”）+ 品牌主题 + 云端工作区 UX 调整。
**零 hack**：全部走 dsh 官方扩展机制（client bundle 插件 + bundle patch 层）。

## 文件结构

```
ui-overlay/magpie-ui-plugin/
├── package.json         # dsh.client 声明（platform: web）+ dsh.bundle.patch
├── lib/
│   ├── index.js         # node 半（no-op，占位）
│   └── client.js        # 浏览器半：品牌 slot 注册 + 主题注入 + 启动页品牌覆盖 + hero 文案改写 + 输入框占位改写 + 工作区入口隐藏
├── cordis.patch.yml     # bundle patch 层：禁用 ui-brand-official + insert 本包 entry
└── assets/              # logo.svg / favicon（当前仅存档，客户端内联 SVG 无需引用）
```

## 工作原理（三个官方机制）

1. **品牌 slot 影子注册**：dsh web 的品牌区是三个命名 slot（`sidebar.brand.mark`、
   `sidebar.brand.name`、`conversation.hero.brand.mark`），官方鲸鱼插件 `dsh-client-ui-brand-official`
   注册进去。本插件的 `client.js` 以 `window.__ModuleLoader__.load()` 注册同名 slot——
   动态注册条目在选举中优先于出厂条目（shadowing），鲸鱼被直接盖掉。

2. **bundle patch 层**：`cordis.patch.yml` 把 `ui-brand-official` 置 `disabled: true`
   （干净移除，不留幽灵条目），并用 `- insert:` 插入本包自己的 loader entry
   （id: `ui-brand-magpie`, name: `@magpie/meta-agent-ui`）。

3. **client-modules 扫描**：dsh 的 node 半扫描所有 loader entry 中声明 `dsh.client` 的包，
   把它们的 `client.js` 注入 `window.__DSH_BOOT__` manifest 并在浏览器加载。
   **关键约束**：包必须能被 dsh 安装树 `require.resolve` 到（与官方包同一解析世界），
   所以插件要在 Dockerfile 里 `npm install --save` 进 dsh 全局包。

## 踩坑记录（务必读）

| 坑 | 现象 | 解法 |
|----|------|------|
| **`- id:` 直接写新行** | `patch: entry "xxx" not found` | 新 entry 必须用 `- insert:` 列表；`- id:` 只改已有行 |
| **只装包不插 entry** | 插件不在 `__DSH_BOOT__`，client.js 404 | client-modules 按 loader entry 名扫描，必须有 entry 行 |
| **包没进 dsh 安装树** | `ERR_MODULE_NOT_FOUND` | 插件必须是 dsh 包的依赖（Dockerfile `npm install --save`），光放 /opt 不够 |
| **profile 卷属主 root** | entrypoint 改 package.json 时 EACCES | 容器内 `--user 0` + `chown -R 1001:1001`（metauser uid 1001，不是 1000！） |
| **patch 语法** | insert 列表元素 `{id, name}`，overrides 是 {id, disabled, config...} | 见 dsh-app-boot/cordis-plugin-include 源码 |

## 部署（Dockerfile / entrypoint 已接入）

- Dockerfile：`COPY ui-overlay/magpie-ui-plugin /opt/magpie-ui-plugin` +
  `cd $(npm root -g)/@deepseek-ai/dsh && npm install /opt/magpie-ui-plugin --save --save-exact`
- entrypoint.sh：启动 dsh web 前，把 `@magpie/meta-agent-ui` 幂等加入
  `$DSH_HOME/profiles/web/package.json` 的 `dsh.profile.bundles`（用 node 写 JSON，
  不需要 pnpm；插件本体已在镜像里）。
- `deploy/sync.sh --fast` 除了覆盖 `workspace/`，还会把本插件的 `lib/client.js` 与
  `assets/*` 覆盖进镜像 `/opt/magpie-ui-plugin`（不重建 R/image 层）。

## 维护

- 改 `lib/client.js` 的主题/文案/隐藏规则后：本地 `dsh plugin --profile web add` 重测 →
  `docker compose build agent-alice && up -d`。
- 本地测试床：`dsh web --no-open --port 3081`（浏览器 127.0.0.1:3081 验证）。
- 检查线上：`docker exec deploy-agent-alice-1 bash /tmp/vb.sh`（magpie_entries=1,
  brand_official=0, client_js_http=200 即正常）。

## 当前线上状态（2026-08-27）

- magpieagent.online 网关 HTTPS → agent 容器全链路验证通过
- boot manifest 含 `@magpie/meta-agent-ui`，官方品牌 0 残留
- Basic Auth 用户：alice（密码已改，未知）、13677074595 / zxc199739（验证用）
