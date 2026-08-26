# Protocol: <标题：Association of X with Y: a systematic review and meta-analysis>

> PROSPERO 注册字段对齐。注册后回填注册号。CRD42026XXXXXX

## 1. Research question (PICO)
在<P人群>中，与<C对照>相比，<I暴露/干预>与<O主要结局>的风险差异是否相关？

- **P (Population)**:
- **I (Intervention/Exposure)**:
- **C (Comparator)**:
- **O (Outcomes)**: 主要结局: ；次要结局:
- **S (Study designs)**:

## 2. Searches
- 数据库: PubMed（必）; Cochrane Library; Embase; （可加 Web of Science）
- 检索时间范围: 至
- 语言限制: 中英文（说明理由：无语言限制更优，若仅限需在局限性讨论）
- 补充策略: 纳入文献参考文献追溯（引文滚雪球）；试验注册库查在研研究
- 完整检索式见 `10-search/search-strategy.md`（检索执行后回填）

## 3. Eligibility criteria
### 纳入标准 (IC)
1. 研究<P>的原创研究
2. 研究<I>与<O>的关系
3. <设计类型>
4. 提供可提取的效应数据（2x2表/RR/OR/HR+CI/均值±SD）

### 排除标准 (EC，与 PRISMA 流程图排除原因一一对应)
1. 研究设计不符（综述/评论/病例报告/会议摘要）
2. 人群不符（如动物实验/健康人群）
3. 暴露/干预不符
4. 结局数据不可用（无法提取效应量且联系作者无回应）
5. 数据重复发表（保留信息量最大/随访最长者）

## 4. Selection process
双人独立筛选（Reviewer A/B），分歧由第三人裁决。本项目执行方式：AI 模拟两名独立评审 + 用户裁决，全部判断留痕于筛选表。

## 5. Data extraction
标准化提取表（见 `templates/extraction_template.csv`）+ 数据字典。双人独立提取，数值不一致时回原文核对裁决。缺失数据：SE/CI→SD 标准换算并记录；无法获得则该研究该结局不进入定量合并。

## 6. Risk of bias assessment
- RCT: Cochrane RoB 2.0
- 队列/病例对照: Newcastle-Ottawa Scale (NOS)
- 剂量-反应观察性: ROBINS-E
- 双人独立评价，分歧裁决

## 7. Synthesis methods
- 效应量: 二分类 OR/RR；连续 MD/SMD (Hedges' g)；生存 lnHR
- 合并模型: 随机效应 (REML) 为默认（假设跨研究真实效应存在变异）；异质性 I²<25% 且方法学同质时辅报固定效应敏感性
- 异质性: τ², I² (25/50/75% 分档), Cochran's Q, 预测区间
- 亚组（预注册，探索性）: <如性别、地区、剂量、研究质量>
- Meta 回归（预注册）: <如平均年龄、随访时长>（k≥10 才执行）
- 发表偏倚: 漏斗图目测 + Egger 检验 + trim-fill（k≥10）；p-curve（k≥5 且效应显著）
- 敏感性: 留一法；按质量高低分组；排除高偏倚研究
- 软件: R <版本> + metafor <版本>（执行后回填）
- 证据质量: GRADE 分级（主要与次要结局各做 Evidence Profile）

## 8. Reporting
PRISMA 2020 清单随稿提交。

## 9. Registration
PROSPERO: https://www.crd.york.ac.uk/prospero/ （提交后回填注册号与日期）

## 10. Amendments
| 日期 | 修改内容 | 理由 |
|------|----------|------|
| | | |
