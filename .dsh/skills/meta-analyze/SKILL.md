---
name: meta-analyze
description: 统计分析与结果可视化。确认分析方案后运行R脚本（metafor/meta/netmeta），产出森林图、漏斗图、敏感性分析、亚组分析和发表级图表。数据提取完成后使用。
whenToUse: analysis_ready.csv就绪、分析方案确认后
---

# 统计分析与可视化（R / metafor 体系）

## 前置（必须逐条确认后才跑 R）
向用户展示并确认《分析方案》：
1. **效应量**：二分类→OR/RR（事件数完整时）；连续→MD/SMD（SMD 需说明换算，Hedges' g 默认）；生存→lnHR
2. **模型**：随机效应（默认，DL/REML 估计器说明）vs 固定效应（仅当 I²<25% 且方法学同质）
3. **k 与功效**：研究数 <5 时不做发表偏倚检验；<10 时漏斗图仅描述性解读
4. **异质性预案**：I² 25/50/75 分档；τ²；预测区间必报
5. **亚组与 meta 回归**：只分析 protocol 预注册的变量（防止数据打捞）
6. **敏感性**：留一法（leave-one-out）、按质量分、按样本量加权
7. **网状 meta**（如适用）：netmeta 包，一致性检查（node-splitting）

## 执行

### R 环境
- 先探测：`which Rscript || ls "/c/Program Files/R/R-4.5.3/bin/Rscript.exe" || ls /usr/local/bin/Rscript`
- Windows 本地：`"/c/Program Files/R/R-4.5.3/bin/Rscript.exe"`；云端容器：`/usr/local/bin/Rscript`
- 必需包已预装：metafor, meta, netmeta, forestplot, ggplot2；缺失时 `install.packages()` 后再跑

### 脚本体系（复制到项目再改，不原地改模板）
`templates/R/` 下：
- `01_run_meta.R`：主分析（读 analysis_ready.csv → rma() → 输出合并效应、异质性、预测区间）
- `02_subgroup_regression.R`：亚组 + meta 回归
- `03_sensitivity_bias.R`：留一法、漏斗图、Egger/Petō、trim-fill、p-curve
- `04_forest_plots.R`：发表级森林图（中英文双模板，300dpi PNG+PDF）
- `05_network_meta.R`：网状 meta（可选）
- `06_dose_response.R`：剂量-反应（dosresmeta 逻辑，可选）

运行方式：
```sh
cd "projects/<slug>/40-analysis"
"/path/to/Rscript.exe" 01_run_meta.R 2>&1 | tee analysis_log.txt
```

### 输出存档纪律
- 每个脚本输出：`out_<n>_<名称>.txt`（完整统计输出）+ 图表 PNG/PDF
- 森林图必须含：每研究效应量+CI、权重%、合并菱形、异质性统计量（τ², I², H², Q 的 p）、预测区间
- 漏斗图配 Egger 检验结果；trim-fill 剪补图另存
- **所有数字以 R 输出为准**，写论文时直接引用输出文件，禁止手改

### 结果解读（给用户的报告）
- 合并效应 + 95%CI + p + 预测区间（人话解释：意味着什么）
- 异质性程度与可能来源
- 敏感性/亚组发现（注明是探索性的）
- 发表偏倚评估结论
- 证据质量：GRADE 分级（高/中/低/很低 + 降级理由）——这是顶刊审稿必问项

## 红线
- 方案未确认不跑正式分析
- R 报错时修复脚本重跑，**绝不手写"预期"结果**
- 亚组分析结论一律标注"探索性，需谨慎解读"（除非 protocol 预注册且功效足够）
