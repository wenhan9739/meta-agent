#!/usr/bin/env Rscript
# ============================================================
# 06_dose_response.R — 剂量-反应 meta 分析 (广义最小二乘, Greenland-Longnecker)
# 输入: dose_response.csv (study_id, dose, cases, person_years|n, logRR, se, 参照剂量行)
# 方法: metafor 的 dosresmeta 逻辑 (通过 do.call(mvmeta) 或 glst 包);
#        本脚本使用 metafor 的 rma(yi, vi, mods=) 两阶段简化法 + 说明限制
# 用法: Rscript 06_dose_response.R --data dose_response.csv
# ============================================================
suppressPackageStartupMessages({library(metafor)})
library(grDevices)

args <- commandArgs(trailingOnly = TRUE)
get_arg <- function(flag, default = NULL) {
  i <- match(flag, args)
  if (!is.na(i) && length(args) >= i + 1) return(args[i + 1]); default
}
data_file <- get_arg("--data", "dose_response.csv")

dat <- read.csv(data_file, stringsAsFactors = FALSE, check.names = FALSE)
need <- c("study_id", "dose", "logRR", "se")
if (!all(need %in% names(dat)))
  stop("需要列: study_id, dose, logRR, se (相对参照剂量的 log 效应及 SE)")

sink("out_6_dose.txt")
cat("==== 剂量-反应 Meta 分析 (两阶段线性) ====\n")
cat("生成时间:", format(Sys.time()), "\n")
cat("注: 本脚本实现两阶段线性趋势 (每研究斜率 + 合并)。\n")
cat("非线性 (限制性立方样条) 与 Greenland-Longnecker 协方差重构需要 dosresmeta 包,\n")
cat("如需非线性建模请安装: install.packages('dosresmeta')\n\n")

# 阶段1: 每个研究的剂量斜率 (logRR ~ dose, 方差加权)
studies <- unique(dat$study_id)
slopes <- do.call(rbind, lapply(studies, function(s) {
  d <- dat[dat$study_id == s, ]
  if (nrow(d) < 2) return(NULL)
  m <- lm(logRR ~ dose, data = d, weights = 1 / (se^2))
  # 斜率方差: 用稳健的 delta 近似 (基于模型协方差 + se 加权)
  v <- summary(m)$cov.unscaled * (summary(m)$sigma^2)
  data.frame(study_id = s, beta = coef(m)[["dose"]], var = v[["dose", "dose"]], n_doses = nrow(d))
}))
slopes <- na.omit(slopes)
cat("有效研究:", nrow(slopes), "\n\n")

# 阶段2: 合并斜率
res <- rma(yi = beta, vi = var, data = slopes, method = "REML")
print(summary(res))
cat("\n解读: 每+1单位暴露剂量, 结局风险变化 exp(beta) 倍\n")
cat("每+1单位: RR =", round(exp(res$beta[1]), 4),
    " 95%CI [", round(exp(res$ci.lb), 4), ",", round(exp(res$ci.ub), 4), "]\n")
sink()

png("fig_dose_response.png", width = 1600, height = 1200, res = 200)
plot(dat$dose, exp(dat$logRR), log = "y",
     xlab = "Dose (units)", ylab = "Relative Risk",
     main = "Dose-response (study-specific points)",
     pch = 19, col = as.numeric(factor(dat$study_id)) %% 8 + 1)
abline(exp(res$beta[1]) ^ 0, 0, lty = 2)
curve(exp(res$beta[1] * x), from = 0, to = max(dat$dose), add = TRUE, lwd = 2)
legend("topleft", "Pooled linear trend", lwd = 2, lty = 1)
dev.off()
cat("完成: out_6_dose.txt / fig_dose_response.png\n")
