#!/usr/bin/env Rscript
# ============================================================
# 01_run_meta.R — 主分析：合并效应 + 异质性 + 预测区间
# 输入: analysis_ready.csv (列: study_id, outcome, event_e/n_e/event_c/n_c
#        或 mean_e/sd_e/n_e/mean_c/sd_c/n_c, 或 yi/vi)
# 输出: out_1_main.txt + fitted_effects.csv
# 用法: Rscript 01_run_meta.R --data analysis_ready.csv --outcome <outcome名> --measure OR
# ============================================================
suppressPackageStartupMessages({library(metafor)})

args <- commandArgs(trailingOnly = TRUE)
get_arg <- function(flag, default = NULL) {
  i <- match(flag, args)
  if (!is.na(i) && length(args) >= i + 1) return(args[i + 1]); default
}
data_file  <- get_arg("--data", "analysis_ready.csv")
outcome_nm <- get_arg("--outcome", NULL)
measure    <- get_arg("--measure", "OR")   # OR|RR|SMD|MD|GEN (GEN=yi/vi直接给定)
method_est <- get_arg("--method", "REML")  # REML|DL|FE

dat <- read.csv(data_file, stringsAsFactors = FALSE, check.names = FALSE)
if (!is.null(outcome_nm)) dat <- dat[dat$outcome == outcome_nm, ]
if (nrow(dat) < 2) stop("有效研究数 <2，无法进行 meta 分析")

# --- 构建效应量 ---
if (measure %in% c("OR", "RR")) {
  need <- c("event_e", "n_e", "event_c", "n_c")
  missing_cols <- setdiff(need, names(dat))
  if (length(missing_cols)) stop("缺少列: ", paste(missing_cols, collapse = ", "))
  # 零格校正 (0.5, 仅当存在零格时)
  dat$event_e[dat$event_e == 0 & dat$n_e > 0] <- 0.5
  dat$event_c[dat$event_c == 0 & dat$n_c > 0] <- 0.5
  esc <- escalc(measure = measure, ai = event_e, n1i = n_e,
                ci = event_c, n2i = n_c, data = dat)
} else if (measure %in% c("SMD", "MD")) {
  need <- c("mean_e", "sd_e", "n_e", "mean_c", "sd_c", "n_c")
  missing_cols <- setdiff(need, names(dat))
  if (length(missing_cols)) stop("缺少列: ", paste(missing_cols, collapse = ", "))
  esc <- escalc(measure = measure, m1i = mean_e, sd1i = sd_e, n1i = n_e,
                m2i = mean_c, sd2i = sd_c, n2i = n_c, data = dat)
} else if (measure == "GEN") {
  if (!all(c("yi", "vi") %in% names(dat))) stop("GEN 需要 yi 和 vi 列")
  esc <- dat
} else stop("不支持的 measure: ", measure)

# --- 主模型 ---
k <- nrow(esc)
if (method_est == "FE" || k < 3) {
  res <- rma(yi, vi, data = esc, method = "FE")
} else {
  res <- rma(yi, vi, data = esc, method = method_est)
}

# --- 输出 ---
sink("out_1_main.txt")
cat("==== Meta 分析主报告 ====\n")
cat("生成时间:", format(Sys.time()), "\n")
cat("数据文件:", data_file, "| 结局:", ifelse(is.null(outcome_nm), "全部", outcome_nm), "\n")
cat("效应量:", measure, "| 模型:", res$method, "| 研究数 k =", k, "\n\n")
print(summary(res))

cat("\n---- 预测区间 ----\n")
if (res$method != "FE") {
  pi <- predict(res)
  print(pi)
} else cat("固定效应模型不计算预测区间\n")

cat("\n---- 逐研究效应量(供森林图核对) ----\n")
print(data.frame(study = esc$study_id, yi = round(esc$yi, 4),
                 ci_lower = round(esc$yi - 1.96 * sqrt(esc$vi), 4),
                 ci_upper = round(esc$yi + 1.96 * sqrt(esc$vi), 4)))
sink()

# 拟合值导出
out <- data.frame(esc$study_id, esc$yi, sqrt(esc$vi), weights(res))
names(out) <- c("study_id", "yi", "sei", "weight_pct")
write.csv(out, "fitted_effects.csv", row.names = FALSE)
cat("完成: out_1_main.txt / fitted_effects.csv\n")
