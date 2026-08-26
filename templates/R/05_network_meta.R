#!/usr/bin/env Rscript
# ============================================================
# 05_network_meta.R — 网状 meta 分析 (netmeta, 频率学派)
# 输入: network_ready.csv (study, treatment, event/n 或 mean/sd/n 长格式)
# 用法: Rscript 05_network_meta.R --data network_ready.csv --measure OR --outcome X
# ============================================================
suppressPackageStartupMessages({library(netmeta)})
library(grDevices)

args <- commandArgs(trailingOnly = TRUE)
get_arg <- function(flag, default = NULL) {
  i <- match(flag, args)
  if (!is.na(i) && length(args) >= i + 1) return(args[i + 1]); default
}
data_file <- get_arg("--data", "network_ready.csv")
measure   <- get_arg("--measure", "OR")
outcome_nm <- get_arg("--outcome", NULL)
sm_label  <- switch(measure, OR = "OR", RR = "RR", SMD = "SMD", MD = "MD", measure)

dat <- read.csv(data_file, stringsAsFactors = FALSE, check.names = FALSE)
if (!is.null(outcome_nm)) dat <- dat[dat$outcome == outcome_nm, ]
need <- c("study", "treatment", "event", "n")
if (!all(need %in% names(dat)))
  stop("网状 meta 需要长格式列: study, treatment, event, n (二分类); 连续型请扩展脚本")
dat$treatment <- factor(dat$treatment)

sink("out_5_nma.txt")
cat("==== 网状 Meta 分析 (netmeta) ====\n")
cat("生成时间:", format(Sys.time()),
    "| 研究:", length(unique(dat$study)),
    "| 处理:", length(levels(dat$treatment)), "\n")
cat("处理列表:", paste(levels(dat$treatment), collapse = ", "), "\n\n")

# 构建网状数据: pairwise 接受长格式 (每行一臂), 同 study 多臂自动生成全部比较对
pw <- pairwise(treat = treatment, event = event, n = n,
               studlab = study, data = dat, sm = measure,
               allstudies = TRUE)
net <- netmeta(TE, seTE, treat1, treat2, studlab,
               data = pw, sm = measure, common = FALSE, random = TRUE)
print(summary(net))

cat("\n---- 网络几何 ----\n")
print(net$A.matrix)  # 比较矩阵
cat("网络连通性:", ifelse(net$n.comparisons > 0, paste(net$n.subnets, "个子网络"), "?"), "\n")

# 一致性检查 (node-splitting, 需要闭合环)
cat("\n---- 不一致性检验 (node-splitting / sidesplitting) ----\n")
try({
  ns <- netsplit(net)
  print(ns)
}, silent = TRUE)
try({
  ds <- netsplit(net, method = "sidesplit")
  print(ds)
}, silent = TRUE)

cat("\n---- 排序 (P-score) ----\n")
print(netrank(net))
sink()

# --- 网络图 ---
png("fig_network.png", width = 1600, height = 1600, res = 200)
n_trt <- length(levels(dat$treatment))
netgraph(net, plastic = FALSE,
         thickness = "number.of.studies",
         points = TRUE, cex.points = rep(2, n_trt),
         number.of.studies = TRUE)
title("Network geometry")
dev.off()

# --- 森林图 (各处理 vs 共同参照, 按 P-score 排序) ---
ref <- levels(dat$treatment)[1]
png("fig_nma_forest.png", width = 2000, height = 1400, res = 200)
forest(net, reference.group = ref,
       sortvar = net$P.score,
       smlab = paste(sm_label, "\n(vs", ref, ")"))
dev.off()
cat("完成: out_5_nma.txt / fig_network.png / fig_nma_forest.png\n")
