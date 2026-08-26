#!/usr/bin/env Rscript
# ============================================================
# 02_subgroup_regression.R — 亚组分析与 meta 回归
# 仅对 protocol 预注册的变量执行；结果标注"探索性"
# 用法: Rscript 02_subgroup_regression.R --data analysis_ready.csv --outcome X --subgroups "year,region" --modvars "age_mean"
# ============================================================
suppressPackageStartupMessages({library(metafor)})

args <- commandArgs(trailingOnly = TRUE)
get_arg <- function(flag, default = NULL) {
  i <- match(flag, args)
  if (!is.na(i) && length(args) >= i + 1) return(args[i + 1]); default
}
data_file <- get_arg("--data", "analysis_ready.csv")
outcome_nm <- get_arg("--outcome", NULL)
subgroups <- strsplit(get_arg("--subgroups", ""), ",")[[1]]
modvars   <- strsplit(get_arg("--modvars", ""), ",")[[1]]

dat <- read.csv(data_file, stringsAsFactors = FALSE, check.names = FALSE)
if (!is.null(outcome_nm)) dat <- dat[dat$outcome == outcome_nm, ]
# 若无 yi/vi 列, 从原始列自动计算
if (!all(c("yi", "vi") %in% names(dat))) {
  if (all(c("event_e", "n_e", "event_c", "n_c") %in% names(dat))) {
    dat$event_e[dat$event_e == 0 & dat$n_e > 0] <- 0.5
    dat$event_c[dat$event_c == 0 & dat$n_c > 0] <- 0.5
    esc <- escalc(measure = "OR", ai = event_e, n1i = n_e,
                  ci = event_c, n2i = n_c, data = dat)
    dat$yi <- esc$yi; dat$vi <- esc$vi
  } else if (all(c("mean_e", "sd_e", "n_e", "mean_c", "sd_c", "n_c") %in% names(dat))) {
    esc <- escalc(measure = "SMD", m1i = mean_e, sd1i = sd_e, n1i = n_e,
                  m2i = mean_c, sd2i = sd_c, n2i = n_c, data = dat)
    dat$yi <- esc$yi; dat$vi <- esc$vi
  } else stop("需要 yi/vi 列, 或 2x2 表列, 或连续型列 (mean/sd/n)")
}
stopifnot(nrow(dat) >= 4)  # meta 回归至少需要足够研究数

sink("out_2_subgroup.txt")
cat("==== 亚组分析与 Meta 回归 (探索性) ====\n")
cat("生成时间:", format(Sys.time()), "| k =", nrow(dat), "\n\n")

# --- 亚组分析 ---
for (v in subgroups) {
  v <- trimws(v)
  if (!v %in% names(dat)) { cat("[跳过] 未找到列:", v, "\n"); next }
  if (length(na.omit(unique(dat[[v]]))) < 2) { cat("[跳过] 无分组变异:", v, "\n"); next }
  cat("---- 亚组:", v, "----\n")
  res <- rma(yi, vi, data = dat, mods = ~ factor(get(v)))
  print(res)
  # 亚组间差异检验 Q_between
  cat("\n")
}

# --- Meta 回归 (连续调节变量) ---
for (v in modvars) {
  v <- trimws(v)
  if (!v %in% names(dat)) { cat("[跳过] 未找到列:", v, "\n"); next }
  valid <- !is.na(dat[[v]])
  if (sum(valid) < 4) { cat("[跳过] 有效研究<4:", v, "\n"); next }
  cat("---- Meta 回归:", v, "----\n")
  res <- rma(yi, vi, data = dat[valid, ], mods = get(v))
  print(res)
  cat("\n")
}
cat("注: 以上均为探索性分析, 需谨慎解读; 预注册变量的结果才可作为确认性结论。\n")
sink()
cat("完成: out_2_subgroup.txt\n")
