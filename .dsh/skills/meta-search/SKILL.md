---
name: meta-search
description: 执行系统性文献检索。构建PubMed/Cochrane/Embase检索式，通过NCBI E-utilities自动执行PubMed检索，去重，产出PRISMA流程图所需的检索计数与题录文件。
whenToUse: protocol确认后需要检索文献时；或用户要求修改/补充检索时
---

# 系统文献检索

## 前置确认
- 读取 `projects/<slug>/00-protocol/protocol.md`，检索式必须覆盖 PICO 全要素
- 若用户提供了本地 PDF 库（如 D:/Hermes agent/paperdownload/），检索后先做本地匹配

## 步骤

### 1. 构建检索式（三層结构）
对每个数据库产出检索式文档 `10-search/search-strategy.md`：
- **PubMed（主检索，自动执行）**：
  - 主题词层：MeSH 词（`"[term]"[Mesh]`）+ 副词扩展
  - 自由词层：Title/Abstract 同义词 OR 组（`[tiab]`），用 OR 汇总同义表达（疾病名、干预名的所有常见变体、缩写）
  - 方法学层：`(meta-analysis[pt] NOT meta-analysis[pt] AND review[pt])` 不适用——这里是找**原始研究**，用研究类型过滤器（RCT: `randomized controlled trial[pt]` 或敏感性更高的 Cochrane RCT filter；队列: `cohort[tiab] OR follow-up[tiab]`）
  - 三层 AND 连接；限制时间与语言放最后（`AND 2015:2026[dp]`）
- **Embase**（Elsevier 语法）：给出 Emtree 词 + `(exp)` 扩展的完整检索式，用户手工执行
- **Cochrane Library**：给出 MeSH/Emtree + free text 的检索行编号式检索策略
- 每条检索式标注：执行日期、命中数

### 2. 自动执行 PubMed 检索（优先用工具脚本）
首选一体化脚本（esearch+efetch+CSV 解析一次完成）：
```sh
python templates/scripts/pubmed_search.py \
  --query '<完整检索式>' --mindate 2015 --maxdate 2026 \
  --out-dir projects/<slug>/10-search
```
产物自动生成：`pubmed_pmids.txt`、`pubmed_raw.txt`（MEDLINE 原始题录）、`all_records.csv`。
- 脚本内置 NCBI 限速（无 key 0.4s/请求）；有 NCBI API key 时传 `--api-key` 或设 `NCBI_API_KEY` 环境变量

手工方式（仅当需要特殊参数时）：E-utilities 注意 URL 编码：
```
curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term=<URL编码检索式>&retmax=0&usehistory=y"
curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id=<id列表>&rettype=medline&retmode=text"
```

### 2b. 跨库去重（检索完成后必须执行）
```sh
python templates/scripts/dedup_records.py \
  --inputs 10-search/all_records.csv 10-search/embase_records.csv \
  --out-dir 10-search
```
规则：DOI 归一 → PMID → 标题归一化；产出 `unique_records.csv`、`duplicates.csv`、`dedup_log.md`（含 PRISMA 计数表）。

### 5. 本地 PDF 匹配（如有本地库）
- 把 unique_records 的 PMID 与本地库文件名（`<PMID>.pdf`）匹配，命中列 `local_pdf=yes`
- 报告：N 篇中 M 篇本地已有全文

### 6. 阶段报告
检索式摘要、各库命中数、去重统计、PRISMA 当前计数、下一步（进入筛选）。

## 红线
- 检索式必须存档且可复现（PRISMA 要求报告完整检索式）
- 不因为命中数太多而擅自加限制条件缩小范围——与用户商量
