---
name: meta-screen
description: 文献筛选。基于纳入排除标准对题录和摘要做双人独立筛选（模拟Reviewer A/B），标注分歧请求用户裁决，维护PRISMA计数，产出纳入清单。
whenToUse: 检索完成、去重后的题录需要筛选时
---

# 文献筛选（双人独立 + 裁决）

## 前置
- 读取 protocol 的纳入/排除标准（IC1-ICn 条目化）
- 读取 `10-search/unique_records.csv`
- 筛选分两轮：**题目/摘要轮** → **全文轮**

## 步骤

### 1. 生成筛选表
`20-screening/screening_t&a.csv`（title&abstract 轮）：
```
record_id, pmid, title, abstract, A_decision, A_reason, B_decision, B_reason, conflict, final, final_reason
```

### 2. 双人独立筛选（核心方法学步骤，不得合并为一次判断）
对每条记录，你分别以两个独立视角判断：
- **Reviewer A**（宽容倾向，倾向纳入，标准：不能确定排除即纳入）
- **Reviewer B**（严格倾向，倾向排除，标准：不能确定纳入即排除）
- 每人独立给出 `include/exclude/unclear` + 排除原因代码（对齐 protocol 的排除标准编号）
- **先完成 A、B 全部判断，再对比**——禁止先出 A 再让 A 影响 B
- `A_decision == B_decision` → 自动定为 final；不一致 → `conflict=yes` 待裁决

### 3. 分歧裁决
- 输出 `20-screening/conflicts.csv` 给用户（含 A/B 各自理由）
- 用户逐条裁决（或授权你按 protocol 解释裁决，但必须逐条记录理由和裁决人=用户/AI-assisted）
- 全文轮同理：`screening_ft.csv`，排除全文必须记录具体原因（这是 PRISMA 排除原因图的输入）

### 4. PRISMA 计数维护
更新 `20-screening/prisma_counts.md`：
- 识别记录数（各库）→ 去重后数 → T&A 排除数 → 全文评估数 → 全文排除数（按原因分列）→ **最终纳入数**
- 数字必须前后闭环，最终纳入清单 `20-screening/included_studies.csv`（pmid, doi, title, study_id 如 Author-Year）

### 5. 阶段报告
筛选漏斗数字、分歧数量与类型、最终纳入 N 篇、下一步（数据提取）。

## 效率规则
- 题录量大（>1000）时：先跑 A/B 筛选脚本化批量处理，每批 50-100 条，分批向用户报进度
- 明显不符的（如动物实验当人类研究排除标准存在时）也要走流程留痕，不静默丢弃

## 红线
- 纳入/排除只依据 protocol 标准，不凭"感觉这篇不好"
- 全文排除原因必须逐篇记录（PRISMA 流程图强制要求）
