---
name: meta-extract
description: 数据提取。生成定制化Excel提取表与提取字典，双人独立提取模拟，处理缺失数据，产出可直接喂给R分析脚本的标准数据集。
whenToUse: 筛选完成、得到纳入研究清单后
---

# 数据提取

## 前置
- 读取 `20-screening/included_studies.csv` 与 protocol 中的结局定义
- 全文获取：优先本地 PDF 库匹配；缺失的用 sci-hub/期刊 OA/用户机构渠道提示用户补齐（列出缺失清单）

## 步骤

### 1. 设计提取表（先和用户确认变量清单）
生成 `30-extraction/extraction_template.csv`（UTF-8-BOM，Excel 友好），标准列组：
- **识别**：study_id, pmid, doi, first_author, year, country, source_db
- **方法学**：study_design, sample_size_total, n_exposed, n_control, followup_months, funding, conflicts_of_interest
- **人群**：age_mean/median, female_pct, disease_severity, inclusion_criteria_summary
- **暴露/干预**：exposure_definition, dose, duration, assessment_method
- **结局（每个主要/次要结局一组）**：events_exposed, events_control（二分类）或 n, mean, sd（连续）；HR/RR/OR + 95%CI + p（生存/已报告效应量）；effect_measure_type 标注
- **质量**：NOS/RoB2 各条目得分, total_score

同时产出 `30-extraction/data_dictionary.csv`：每列的定义、单位、允许值、提取规则（如"效应量优先级：报告HR用HR；仅2x2表则自行计算OR"）

### 2. 双人独立提取（同筛选的双人纪律）
- Reviewer A/B 分别从全文提取 → `extraction_A.csv` / `extraction_B.csv`
- 数值型字段不一致超过舍入容差 → 列入 `extraction_conflicts.csv` 请用户裁决
- 提取时**记录页码/表号**（`source_location` 列）供核对

### 3. 缺失数据处理
- 缺失 SD 但有 SE/CI/p 值 → 按标准公式换算（记录换算过程）
- 完全缺失 → 不填补，标记 `missing`，在报告中说明；连续型结局缺失超过 1/3 研究时提醒用户考虑联系原作者
- 生成分析就绪数据集 `30-extraction/analysis_ready.csv`（一行一个效应量估计 = arm-level 或 study-level 长格式，含 `outcome` 列区分多个结局）

### 4. 阶段报告
提取完成度、冲突数、缺失数据概况、数据集结构预览（前 5 行）、下一步（统计分析方案确认）。

## 红线
- 提取表结构必须先经用户确认再开始提取（返工成本高）
- 换算公式必须记录在 data_dictionary 或单独 notes 文件中
- 不编造任何数字；读不到的字段就是 missing
