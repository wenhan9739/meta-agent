#!/usr/bin/env Rscript
# ============================================================
# 03_sensitivity_bias.R — 敏感性分析(留一法) + 发表偏倚
# 漏斗图/Egger/trim-fill 仅在 k>=10 时做正式检验 (k<10 仅描述)
# 用法: Rscript 03_sensitivity_bias.R --data analysis_ready.csv --outcome X
# ============================================================
suppressPackageStartupMessages({library(metafor)})
library(grDevices)

args <- commandArgs(trailingOnly = TRUE)
get_arg <- function(flag, default = NULL) {
  i <- match(flag, args)
  if (!is.na(i) && length(args) >= i + 1) return(args[i + 1]); default
}
data_file <- get_arg("--data", "analysis_ready.csv")
outcome_nm <- get_arg("--outcome", NULL)

dat <- read.csv(data_file, stringsAsFactors = FALSE, check.names = FALSE)
if (!is.null(outcome_nm)) dat <- dat[dat$outcome == outcome_nm, ]
# 若无 yi/vi 列, 从二分类或连续型原始列计算 (复用 01 的逻辑)
if (!all(c("yi", "vi") %in% names(dat))) {
  if (all(c("event_e", "n_e", "event_c", "n_c") %in% names(dat))) {
    dat$event_e[dat$event_e == 0 & dat$n_e > 0] <- 0.5
    dat$event_c[dat$event_c == 0 & dat$n_c > 0] <- 0.5
    esc <- escalc(measure = "OR", ai = event_e, n1i = n_e,
                  ci = event_c, n2i = n_c, data = dat)
    dat$yi <- esc$yi; dat$vi <- esc$vi
    cat("[提示] 从 2x2 表自动计算 OR 效应量\n")
  } else if (all(c("mean_e", "sd_e", "n_e", "mean_c", "sd_c", "n_c") %in% names(dat))) {
    esc <- escalc(measure = "SMD", m1i = mean_e, sd1i = sd_e, n1i = n_e,
                  m2i = mean_c, sd2i = sd_c, n2i = n_c, data = dat)
    dat$yi <- esc$yi; dat$vi <- esc$vi
    cat("[提示] 从连续型统计量自动计算 SMD\n")
  } else stop("需要 yi/vi 列, 或 2x2 表列 (event_e,n_e,event_c,n_c), 或连续型列 (mean/sd/n)")
}
k <- nrow(dat)

res <- rma(yi, vi, data = dat, method = "REML")

# OR/RR 时漏斗图 x 轴用 log 尺度标签
xlab_funnel <- if (all(c("event_e", "n_e", "event_c", "n_c") %in% names(dat)))
  "Effect estimate (log scale)" else "Effect estimate"

sink("out_3_sensitivity.txt")
cat("==== 敏感性分析与发表偏倚 ====\n")
cat("生成时间:", format(Sys.time()), "| k =", k, "\n\n")

# --- 留一法 ---
cat("---- Leave-one-out 敏感性分析 ----\n")
loo <- leave1out(res)
loo_tab <- data.frame(dat$study_id, loo)
names(loo_tab)[1] <- "omitted_study"
print(loo_tab, row.names = FALSE)
cat("\n合并效应波动范围: [", round(min(loo$estimate), 4), ",", round(max(loo$estimate), 4), "]\n")
cat("任一研究剔除后结论是否改变: ",
    ifelse(all(sign(loo$estimate) == sign(res$beta[1]) & loo$pval < 0.05), "否 (稳健)",
           "是 (存在影响较大的研究, 见上表)\n"))

# --- 发表偏倚 ---
cat("\n---- 发表偏倚 ----\n")
if (k >= 10) {
  cat("Rank correlation (Kendall's tau):\n")
  print(ranktest(res))
  cat("\nRegression test (Egger):\n")
  print(regtest(res, model = "rma"))
  cat("\nTrim-and-fill:\n")
  tf <- trimfill(res)
  print(tf)
  cat("填补研究数:", tf$k0, "\n")
} else {
  cat("k =", k, "< 10: 不做正式偏倚检验 (检验效能不足), 仅漏斗图描述性评估。\n")
}
sink()

# --- 漏斗图 ---
png("fig_funnel.png", width = 1600, height = 1200, res = 200)
funnel(res, main = paste("Funnel plot (k =", k, ")"), xlab = xlab_funnel)
if (k >= 10) {
  tf_plot <- trimfill(res)
  funnel(tf_plot, main = "Funnel with trim-fill", shade = "gray",
         xlab = xlab_funnel)
}
dev.off()
cat("完成: out_3_sensitivity.txt / fig_funnel.png\n")
