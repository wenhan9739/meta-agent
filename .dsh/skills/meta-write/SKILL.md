---
name: meta-write
description: 全文撰稿。按IMRaD结构撰写系统综述全文（PRISMA 2020对齐），生成摘要、标题页、参考文献，输出Markdown+Word双格式。统计分析完成后使用。
whenToUse: 分析完成、图表定稿后
---

# 全文撰稿（IMRaD / PRISMA 2020）

## 前置
- 汇集：protocol、PRISMA 计数、分析输出、图表清单、GRADE 分级
- 确认目标期刊风格（若未选刊，先按通用 ICMJE 格式写，选刊后再调）

## 结构与写作要点

### Title Page
标题（含研究设计、必要时注明 "PRISMA-compliant"）、作者与单位（占位）、通讯作者、利益冲突、资助、数据可用性声明、PROSPERO 注册号（占位待回填）

### Abstract（结构化，≤350词）
Background / Methods（含注册号、检索截止日期）/ Results（**必须含**：纳入 k 项研究 n 名参与者、合并效应量+95%CI+I²、主要亚组发现）/ Conclusions / 注册号
- 摘要最后写，但先列要点框架给用户确认

### Introduction（3段式）
1. 临床背景与疾病负担（引流行病学数据，标注引用需求）
2. 已有证据与争议、已有 meta 的不足（呼应选题评估报告）
3. 本研究目的（一句话，与 protocol 完全一致）

### Methods（与 protocol 严格一致，用过去时）
- 按 PRISMA 2020 条目组织：检索（数据库、时间、语言）→ 筛选（双人+裁决）→ 提取（双人+字典）→ 质量评价工具 → 统计方法（效应量、模型、软件版本 `R x.y.z + metafor x.y`、异质性、偏倚检验、GRADE）
- **方法学透明是系统综述的命**：所有细节可复现

### Results（只报告，不解读）
- 研究流程（引 PRISMA 流程图）+ 研究特征表（Table 1）+ 质量评价表
- 主分析（引森林图 Figure 2）：合并效应、异质性、预测区间
- 亚组/敏感性/发表偏倚（引对应图表）

### Discussion（4段式）
1. 主要发现一段话总结（效应量+CI+确定性）
2. 与已有文献和已有 meta 对比（呼应 Introduction 的 gap）
3. 机制解释与亚组发现解读（标注探索性）
4. 局限性（必写：纳入研究质量、异质性、发表偏倚残留、本综述方法学局限）+ 未来研究方向
- Conclusions：谨慎、与结果严格对齐，不夸大（"associated" 不写 "causes"）

### 图表清单（PRISMA 2020 标准配置）
- Figure 1: PRISMA 流程图（用模板生成）
- Figure 2: 主分析森林图
- Figure 3: 漏斗图（或 trim-fill）
- Figure 4+: 亚组森林图/敏感性
- Table 1: 研究特征；Table 2: 质量评价；Table 3: GRADE 证据概要表（Evidence Profile）
- 补充材料：检索式、排除原因表、全部森林图、meta 回归、Egger、留一法

## 产出
- `50-manuscript/manuscript.md`（主文件，YAML 头含期刊元数据）
- `50-manuscript/references.bib`（PubMed 导出，PMID 溯源）
- Word 版：优先 pandoc（`pandoc manuscript.md -o manuscript.docx --citeproc --bibliography=references.bib`）；无 pandoc 时用 R `templates/R/07_export_docs.R`（生成 Word 可直接打开的 .doc 与 Excel 表格，无需额外包）；都不行时交付 Markdown + 说明
- `50-manuscript/prisma_flowchart`：按 `templates/prisma_flowchart.md` 生成（数字来自 prisma_counts.md）

## 红线
- Results 中每个数字必须能在 40-analysis/ 输出文件中找到出处
- Discussion 不引入 Results 没有的新数据
- 参考文献逐条与 PMID 核对，不虚构文献
- AI 辅助撰写的披露：按目标期刊 AI 政策在 Acknowledgements/Methods 加声明（默认加，用户可要求删）
