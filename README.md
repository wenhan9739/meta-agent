# Meta-Agent 🧬

**基于 DeepSeek Harness 的端到端系统综述 / Meta 分析垂直智能体**

> **版本 `v0.1`**（统一本地 / GitHub / 服务器三端实现；含 CENTRAL 检索、PRISMA 流程图模板、跨库去重增强）

从选题到投稿，用户在 Web UI 中用自然语言下达指令，Meta-Agent 自动完成系统综述全流程：选题评估 → PROSPERO protocol → 文献检索 → 双人筛选 → 数据提取 → R 统计分析 → 发表级可视化 → 全文撰稿 → 选刊与投稿件。

> ⚠️ **预览声明**：本项目基于 DeepSeek Harness (developer preview) 构建，AI 生成的分析结果与文稿需研究者自行核实后方可用于学术用途。本工具不构成医疗建议。

---

## ✨ 核心特性

- **九阶段全流程编排**：每个阶段对应一个技能（skill），agent 按流程纪律推进，不跳步、不编造
- **方法学合规内置**：
  - PRISMA 2020 全程对齐（检索式存档、排除原因逐篇记录、流程图数字闭环校验）
  - 双人独立筛选/提取模拟（Reviewer A 宽容倾向 vs Reviewer B 严格倾向 + 用户裁决）
  - GRADE 证据分级、发表偏倚检验（k≥10 才做正式检验）、预测区间必报
- **真实可用的检索管线**：NCBI E-utilities 一体化 PubMed 检索（限速合规、断点重试、MEDLINE→CSV 自动解析）、CENTRAL (Cochrane) Playwright 自动检索、跨库去重（DOI→PMID→标题归一化三级规则）
- **R 统计全家桶**：metafor 体系 7 个开箱即用脚本——主分析/亚组回归/敏感性+偏倚/森林图/网状 meta/剂量-反应/文档导出
- **发表级输出**：300dpi 森林图（合并菱形与预测区间分离排版）、Word/Excel 兜底导出（无 pandoc 环境）
- **商业化就绪的部署包**：Docker 镜像 + Caddy 网关 + 每用户一容器隔离 + 统一 API Key 计费架构

## 📐 架构

```
用户 (Web UI 自然语言)
        │
        ▼
DeepSeek Harness (dsh web)          ← agent 运行时
├── AGENTS.md                       ← 人格 + 九阶段流程纪律
├── .dsh/skills/meta-*              ← 8 个阶段技能 (自动热加载)
└── workspace: templates/ projects/
        │
        ├── templates/scripts/ ──► NCBI E-utilities (真实文献检索)
        ├── templates/R/ ──────► R/metafor (统计分析与图表)
        └── projects/<slug>/ ──► 项目产物 (PRISMA/protocol/manuscript...)
```

## 🚀 快速开始（本地）

### 前置要求

| 依赖 | 版本 | 用途 |
|---|---|---|
| Node.js | ≥22.19 或 ≥24 | dsh CLI |
| R | ≥4.3 | 统计分析 |
| R 包 | metafor, meta, netmeta, forestplot, ggplot2 | 预装或首次运行时安装 |
| Python | 3.10+ | 检索脚本（仅标准库） |
| DeepSeek API Key | — | [platform.deepseek.com](https://platform.deepseek.com/) 获取 |

### 安装与启动

```bash
# 1. 安装 dsh
npm install -g @deepseek-ai/dsh

# 2. 克隆本项目
git clone https://github.com/wenhan9739/meta-agent.git
cd meta-agent

# 3. 配置 API Key（二选一）
export DEEPSEEK_API_KEY=sk-your-key        # 方式A: 环境变量
# 或方式B: 写入 ~/.dsh/.credentials.yaml:
#   version: 1
#   refs:
#     DEEPSEEK_API_KEY: sk-your-key

# 4. 启动（在本目录下运行 —— 工作区即项目根）
dsh web --no-open
# 浏览器访问 http://127.0.0.1:3080，选择工作区为当前目录
```

### 第一次对话

在 Web UI 输入框试试：

```
我想做"他汀类药物与结直肠癌风险"的 meta 分析，帮我立项。
```

Agent 将进入 PICO 澄清 → 新颖性评估 → 生成项目骨架 → 撰写 PROSPERO 格式 protocol。之后你可以说：

```
执行检索阶段                    # 调用 pubmed_search.py 真实检索 PubMed
继续筛选                        # Reviewer A/B 双人模拟 + 分歧裁决
数据提取完了，开始统计分析       # 先确认方案再跑 R
帮我选刊并准备投稿件             # 期刊匹配报告 + cover letter
```

## 📁 项目结构

```
meta-agent/
├── AGENTS.md                  # Agent 人格与九阶段流程纪律（自动注入会话）
├── .dsh/skills/               # 8 个阶段技能
│   ├── meta-topic/            #   选题评估 + PICO + PROSPERO protocol
│   ├── meta-search/           #   检索策略 + E-utilities 执行 + 去重
│   ├── meta-screen/           #   双人独立筛选 + PRISMA 计数
│   ├── meta-extract/          #   提取表设计 + 缺失数据换算
│   ├── meta-analyze/          #   分析方案确认 + R 执行纪律
│   ├── meta-write/            #   IMRaD 全文 + AI 披露声明
│   ├── meta-journal/          #   选刊(掠夺性期刊强制核验) + 投稿件
│   └── meta-status/           #   项目看板与多项目管理
├── templates/
│   ├── R/                     # 7 个已验证的分析脚本 (metafor 体系)
│   │   ├── 01_run_meta.R         主分析: 合并效应+异质性+预测区间
│   │   ├── 02_subgroup_regression.R  亚组+meta 回归
│   │   ├── 03_sensitivity_bias.R     留一法+漏斗图+Egger+trim-fill
│   │   ├── 04_forest_plots.R         发表级森林图 (PNG/PDF 300dpi)
│   │   ├── 05_network_meta.R         网状 meta (netmeta)
│   │   ├── 06_dose_response.R        剂量-反应 (两阶段线性)
│   │   └── 07_export_docs.R          Word/Excel 兜底导出
│   ├── scripts/
│   │   ├── pubmed_search.py      E-utilities 一体化检索
│   │   ├── central_search.py     CENTRAL (Cochrane) Playwright 检索
│   │   └── dedup_records.py      跨库去重 (DOI→PMID→标题)
│   ├── extraction_template.csv   数据提取表 (双人提取用)
│   ├── data_dictionary.csv       提取字典 (换算公式留痕)
│   ├── prisma_counts.md          PRISMA 计数闭环表
│   ├── prisma_flowchart.md       PRISMA 2020 流程图模板 (Mermaid)
│   ├── protocol_template.md      PROSPERO 对齐 protocol
│   ├── cover_letter_template.md  Cover letter
│   └── PROJECT_board_template.md 项目状态看板
├── projects/                   # 用户项目数据 (每项目独立子目录)
├── deploy/                     # 商业化云端部署包
│   ├── Dockerfile              # node24 + R + metafor + dsh 镜像
│   ├── docker-compose.yml      # per-user 容器隔离
│   ├── Caddyfile               # TLS + 认证 + 子域路由
│   ├── entrypoint.sh           # loopback 绑定 + socat 转发
│   └── DEPLOY.md               # 部署指南 + 合规清单
└── README.md
```

## ☁️ 云端部署（商业化）

单机起步架构：**Caddy 网关（TLS+认证+路由）→ 每用户一个 meta-agent 容器 → DeepSeek API（服务端统一 Key 计费）**

关键安全决策（源码级调研结论）：
- `dsh web` 明确拒绝绑定 0.0.0.0（防 RCE）→ 容器内绑 loopback + socat 出边界
- dsh 的 trust fence 不是认证层 → 认证由网关承担
- settings/credentials 特权 API 钉死 loopback → 经网关的用户无法读取服务端计费 Key

详见 [deploy/DEPLOY.md](deploy/DEPLOY.md)。

## 🔒 设计红线（质量承诺）

- 数字必须可溯源：论文中每个统计量都能对应到 `40-analysis/` 的 R 输出文件
- 不编造任何数据；R 报错修复重跑，绝不手写"预期"结果
- 亚组分析一律标注"探索性"；主要结局由用户确认而非 agent 决定
- 参考文献逐条 PMID 核对；不推荐掠夺性期刊（Beall's List 后继名单核验）
- 医疗免责声明内置

## 🗺️ Roadmap

**近期优先级（ranked）**
1. OIDC 认证替换 Basic Auth（注册/付费墙）— 商业化上线前置
2. token 级用量计量与对账（对接 DeepSeek 用量 API）— 计费闭环
3. 全文自动获取增强（OA 优先级策略、机构代理桥接）— 扩展检索管线召回
4. 引文滚动雪球检索自动化（Web of Science API）— 补检索完整性
5. Web UI 内嵌 PRISMA 流程图交互式编辑 — 投稿体验

**本阶段已落地**
- CENTRAL (Cochrane) Playwright 自动检索脚本，与 PubMed 记录 schema 对齐，可并入跨库去重
- `templates/prisma_flowchart.md`（PRISMA 2020 流程图模板，Mermaid），补齐 meta-write 引用链
- `dedup_records.py` 支持数据库可读命名（PubMed/CENTRAL/Embase）与 CENTRAL 字段透传

## 🤝 贡献

欢迎 Issue 与 PR。提交前请跑通 `templates/R/` 下脚本的冒烟测试（合成数据即可）。

## 📄 License

MIT © 2026 — 使用本项目构建的服务请遵守 DeepSeek Harness (MIT) 与 NCBI E-utilities 使用政策。

## 🙏 致谢

- [DeepSeek AI](https://github.com/deepseek-ai/deepseek-harness) — DeepSeek Harness agent 运行时
- [metafor](https://metafor-project.org/) / [netmeta](https://github.com/guido-s/netmeta) — R meta 分析生态
- PRISMA 2020 与 Cochrane Handbook 方法学框架
