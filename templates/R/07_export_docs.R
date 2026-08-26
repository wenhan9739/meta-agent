#!/usr/bin/env Rscript
# ============================================================
# 07_export_docs.R — 分析结果导出为投稿用文档格式
# 无 pandoc 环境的兜底: 用 base R 写 .docx(HTML伪装)与 .xls(XML表格)
# Excel 打开 .xls (SpreadsheetML XML) 完全兼容; Word 打开 .doc (HTML) 兼容
# 输入: fitted_effects.csv + out_1_main.txt 所在目录
# 用法: Rscript 07_export_docs.R --dir ./40-analysis --title "Table S1. Study-level effects"
# ============================================================
library(grDevices)

args <- commandArgs(trailingOnly = TRUE)
get_arg <- function(flag, default = NULL) {
  i <- match(flag, args)
  if (!is.na(i) && length(args) >= i + 1) return(args[i + 1]); default
}
dir_out <- get_arg("--dir", ".")
doc_title <- get_arg("--title", "Meta-analysis results")

esc <- function(x) {
  x <- as.character(x)
  x <- gsub("&","&amp;",x); x <- gsub("<","&lt;",x); x <- gsub(">","&gt;",x)
  x
}

# ---------- 1. 效应量表 -> Excel(.xls SpreadsheetML) ----------
fe_path <- file.path(dir_out, "fitted_effects.csv")
if (file.exists(fe_path)) {
  dat <- read.csv(fe_path, check.names = FALSE)
  xml_rows <- paste0(
    apply(dat, 1, function(row)
      paste0("<Row>", paste0(sprintf('<Cell><Data ss:Type="String">%s</Data></Cell>', esc(row)), collapse=""), "</Row>")),
    collapse = "\n"
  )
  header_row <- paste0("<Row>",
    paste0(sprintf('<Cell ss:StyleID="hdr"><Data ss:Type="String">%s</Data></Cell>', esc(names(dat))), collapse=""),
    "</Row>")
  xls_xml <- sprintf('<?xml version="1.0"?>
<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet" xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">
 <Styles><Style ss:ID="hdr"><Font ss:Bold="1"/><Interior ss:Color="#D9E2F3" ss:Pattern="Solid"/></Style></Styles>
 <Worksheet ss:Name="Effects">
  <Table>%s\n%s</Table>
 </Worksheet>
</Workbook>', header_row, xml_rows)
  writeLines(enc2utf8(xls_xml), file.path(dir_out, "effect_sizes_table.xls"), useBytes = TRUE)
  cat("导出: effect_sizes_table.xls (Excel 可直接打开)\n")
} else message("跳过 effect table: 未找到 fitted_effects.csv")

# ---------- 2. 统计输出 -> Word 可打开的 .doc (HTML) ----------
txt_path <- file.path(dir_out, "out_1_main.txt")
if (file.exists(txt_path)) {
  txt_lines <- readLines(txt_path, warn = FALSE)
  html_body <- paste0(
    "<p style='font-family:Consolas,monospace;font-size:10pt;white-space:pre-wrap;margin:2px 0;'>",
    esc(txt_lines), "</p>", collapse = "\n"
  )
  html_doc <- sprintf('<!DOCTYPE html><html><head><meta charset="utf-8"><title>%s</title></head>
<body><h2>%s</h2>%s</body></html>',
    esc(doc_title), esc(doc_title), html_body)
  # Word 直接打开 .doc 扩展名的 HTML 文件并按文档渲染
  writeLines(enc2utf8(html_doc), file.path(dir_out, "analysis_report.doc"), useBytes = TRUE)
  cat("导出: analysis_report.doc (Word 可直接打开)\n")
} else message("跳过 report: 未找到 out_1_main.txt")

# ---------- 3. PRISMA 计数表模板填充检查 ----------
cat("完成。提示: 若部署环境有 pandoc, 优先用 pandoc manuscript.md -o manuscript.docx --citeproc\n")
