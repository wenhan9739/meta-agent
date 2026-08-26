---
name: meta-topic
description: Meta分析选题评估与PROSPERO protocol撰写。确认PICO、评估选题新颖性与可行性、生成纳入排除标准、产出注册用protocol文件。新项目从这里开始。
whenToUse: 用户提出一个meta分析想法或要求开始新项目时
---

# Meta 分析选题与立项

## 你的任务
把用户的研究想法变成一个方法学上站得住的、可注册的 meta 分析项目。

## 步骤

### 1. 需求澄清（必须先做）
向用户确认：
- **研究问题**：粗略主题是什么？
- **PICO 拆解**：
  - P (Population)：研究对象、疾病、人群特征
  - I (Intervention/Exposure)：干预或暴露
  - C (Comparison)：对照
  - O (Outcomes)：主要结局 + 次要结局（主要结局只能有一个，必须明确）
  - S (Study design)：RCT？队列？病例对照？诊断试验？
- **时间范围与语言**：检索起止年份；是否仅限中英文
- **用户已有资源**：是否已有文献库/数据？（有数据可跳过检索阶段）

### 2. 选题评估（诚实评估，商业化信誉第一）
用 web 搜索快速核查（PubMed 为主）：
- **新颖性**：近 3 年是否已有高度相似 meta？搜 `"<主题>" AND (meta-analysis[pt] OR systematic review[pt])`
- **已有 meta 存在时**：不直接否决，评估差异化角度（新亚组、新结局、人群更新、网状 meta、剂量-反应），并明确告诉用户"更新型 meta 需要说明与已有版本的差异"
- **可行性**：预估原始研究数量（PubMed 检索量级）。<5 个研究 → 提醒可能不适合定量合并；>200 个 → 提醒工作量和筛选策略
- 输出《选题评估报告》：新颖性判断、差异化建议、预估工作量、风险点

### 3. 生成项目骨架
项目 slug 用 `YYYYMMDD-短主题`（如 `20260826-nsaids-cancer`）：
```
projects/<slug>/{00-protocol,10-search,20-screening,30-extraction,40-analysis,50-manuscript,60-submission}
```
创建 `projects/<slug>/PROJECT.md` 状态看板，填入 PICO 与当前状态。

### 4. 撰写 Protocol（英文，存 00-protocol/）
产出 `protocol.md`，结构对齐 PROSPERO 注册字段：
1. Title（含 "systematic review and meta-analysis"）
2. Research question（PICO 一句话）
3. Searches：计划数据库（PubMed 必选；Cochrane/Embase/Web of Science 按需）、时间范围、语言限制
4. Condition or domain being studied
5. Participants/Population，Intervention/Exposure，Comparator，Outcomes（主要/次要分开写清）
6. Types of study to be included
7. Selection process：独立双人筛选 + 第三人裁决（本项目中由 Reviewer A/B 模拟 + 用户裁决）
8. Data extraction：变量清单（引用提取字典模板）
9. Risk of bias assessment：RCT 用 RoB 2，观察性用 ROBINS-E 或 NOS，诊断试验用 QUADAS-2
10. Synthesis methods：效应量（OR/RR/SMD/HR 按数据类型）、模型（随机效应为默认，理由写明）、异质性（I² 阈值与处理）、亚组/敏感性/meta 回归计划、发表偏倚（漏斗图+Egger，≥10 个研究才做）
11. Reporting：PRISMA 2020
12. Registration：PROSPERO 提交指引（用户自行提交，注册号回填）

### 5. 阶段报告
向用户输出：评估结论 → 项目目录 → protocol 位置 → 下一步（确认 protocol 后进入检索，或先去 PROSPERO 注册）。

## 红线
- 不替用户决定临床意义上的"主要结局"——给出建议但让用户确认
- 评估报告必须如实，选题撞车就说撞车，这是商业信誉
