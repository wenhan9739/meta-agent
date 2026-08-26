#!/usr/bin/env Rscript
# ============================================================
# 04_forest_plots.R — 发表级森林图 (metafor 内置 + ggplot2 双引擎)
# 输出 300dpi PNG + PDF, 含权重/异质性/预测区间
# 用法: Rscript 04_forest_plots.R --data analysis_ready.csv --outcome X --label "Figure 2. xxx"
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
fig_label <- get_arg("--label", "Forest plot")
measure   <- get_arg("--measure", "OR")

dat <- read.csv(data_file, stringsAsFactors = FALSE, check.names = FALSE)
if (!is.null(outcome_nm)) dat <- dat[dat$outcome == outcome_nm, ]
# 若无 yi/vi 列, 从原始列自动计算
if (!all(c("yi", "vi") %in% names(dat))) {
  if (all(c("event_e", "n_e", "event_c", "n_c") %in% names(dat))) {
    dat$event_e[dat$event_e == 0 & dat$n_e > 0] <- 0.5
    dat$event_c[dat$event_c == 0 & dat$n_c > 0] <- 0.5
    esc <- escalc(measure = measure, ai = event_e, n1i = n_e,
                  ci = event_c, n2i = n_c, data = dat)
    dat$yi <- esc$yi; dat$vi <- esc$vi
    cat("[提示] 从 2x2 表计算", measure, "\n")
  } else if (all(c("mean_e", "sd_e", "n_e", "mean_c", "sd_c", "n_c") %in% names(dat))) {
    esc <- escalc(measure = measure, m1i = mean_e, sd1i = sd_e, n1i = n_e,
                  m2i = mean_c, sd2i = sd_c, n2i = n_c, data = dat)
    dat$yi <- esc$yi; dat$vi <- esc$vi
    cat("[提示] 从连续型统计量计算", measure, "\n")
  } else stop("需要 yi/vi 列, 或 2x2 表列, 或连续型列 (mean/sd/n)")
}
k <- nrow(dat)
res <- rma(yi, vi, data = dat, method = "REML")

# atransf: OR/RR 显示时取幂
transf <- if (measure %in% c("OR", "RR")) exp else NULL
xlab   <- switch(measure, OR = "Odds Ratio (log scale)", RR = "Risk Ratio (log scale)",
                 SMD = "Standardized Mean Difference", MD = "Mean Difference",
                 "Effect estimate")

# --- 主森林图 (预留预测区间行空间, 避免标签重叠) ---
has_pi <- res$method != "FE"
extra_rows <- if (has_pi) 2 else 0   # 预测区间行 + 分隔
png("fig_forest_main.png", width = 2400, height = max(1400, 120 * (k + extra_rows) + 500), res = 220)
par(mar = c(4.5, 4.2, 2.5, 2.2), las = 1)
forest(res, atransf = transf, xlab = xlab,
       main = fig_label,
       slab = dat$study_id,
       mlab = "Pooled estimate (RE)",
       ylim = c(-1.8 - extra_rows, k + 3))
# 底部叠加预测区间多边形 (与合并菱形错开一行)
if (has_pi) {
  pi <- predict(res)
  addpoly(pi$pred, pi$ci.lb, pi$ci.ub, row = -1.5,
          mlab = "Prediction interval")
}
dev.off()

pdf("fig_forest_main.pdf", width = 10, height = max(6, 0.45 * (k + extra_rows) + 3))
par(mar = c(4.5, 4.2, 2.5, 2.2), las = 1)
forest(res, atransf = transf, xlab = xlab, main = fig_label,
       slab = dat$study_id, mlab = "Pooled estimate (RE)",
       ylim = c(-1.8 - extra_rows, k + 3))
if (has_pi) {
  pi <- predict(res)
  addpoly(pi$pred, pi$ci.lb, pi$ci.ub, row = -1.5,
          mlab = "Prediction interval")
}
dev.off()

# --- 亚组森林图 (如有分组变量) ---
sg <- get_arg("--subgroup", NULL)
if (!is.null(sg) && sg %in% names(dat)) {
  dat$.g <- factor(dat[[sg]])
  png("fig_forest_subgroup.png", width = 2400, height = max(1600, 130 * k + 600), res = 220)
  par(mar = c(4.5, 4.2, 2.5, 2.2), las = 1)
  res_g <- rma(yi, vi, data = dat, mods = ~ .g, method = "REML")
  forest(res_g, atransf = transf, xlab = xlab,
         main = paste(fig_label, "- by", sg), slab = dat$study_id)
  dev.off()
}

cat("完成: fig_forest_main.png/.pdf",
    if (!is.null(sg)) "fig_forest_subgroup.png" else "", "\n")
