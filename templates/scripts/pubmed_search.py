#!/usr/bin/env python3
# ============================================================
# pubmed_search.py — PubMed 系统检索一体化工具 (NCBI E-utilities)
# 功能: esearch 计数+取PMID → efetch MEDLINE 题录 → 解析为CSV
# 用法:
#   python pubmed_search.py --query '("COPD"[MeSH]) AND ("glucocorticoids"[MeSH])' \
#     --mindate 2015 --maxdate 2026 --out-dir ./10-search [--api-key XXX]
# 产物: pubmed_pmids.txt, pubmed_raw.txt(MEDLINE), all_records.csv
# 遵守 NCBI 限速: 无key 0.4s/请求, 有key 0.11s/请求
# ============================================================
import argparse, csv, os, re, sys, time, urllib.parse, urllib.request

BASE = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils"

def http_get(url, retries=3):
    for i in range(retries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "meta-agent/1.0"})
            with urllib.request.urlopen(req, timeout=60) as r:
                return r.read().decode("utf-8", errors="replace")
        except Exception as e:
            if i == retries - 1: raise
            print(f"  retry {i+1}: {e}", file=sys.stderr)
            time.sleep(2 ** i)

def parse_medline(text):
    """MEDLINE 格式解析 -> 记录列表"""
    records, cur = [], {}
    last_tag = None
    for line in text.splitlines():
        m = re.match(r"^([A-Z]{1,4})\s*-\s?(.*)$", line)
        if m:
            tag, val = m.group(1), m.group(2).strip()
            if tag == "PMID" and cur:
                records.append(cur); cur = {}
            if tag in cur and tag != "MH":  # 多值字段拼接(如FAU/AU/AB不常见但保险)
                cur[tag] += " " + val
            else:
                cur[tag] = val
            last_tag = tag
        elif line.startswith("      ") and last_tag:  # 续行
            cur[last_tag] += " " + line.strip()
    if cur: records.append(cur)
    return records

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--query", help="PubMed 检索式（与 --query-file 二选一）")
    ap.add_argument("--query-file", help="从文件读取检索式（避免 shell 引号转义问题）")
    ap.add_argument("--mindate"); ap.add_argument("--maxdate")
    ap.add_argument("--datetype", default="pdat")
    ap.add_argument("--out-dir", default="./10-search")
    ap.add_argument("--api-key", default=os.environ.get("NCBI_API_KEY", ""))
    ap.add_argument("--retmax-cap", type=int, default=10000)
    a = ap.parse_args()
    if not a.query and not a.query_file:
        ap.error("必须提供 --query 或 --query-file 之一")
    if a.query_file:
        with open(a.query_file, encoding="utf-8") as f:
            a.query = f.read().strip()

    os.makedirs(a.out_dir, exist_ok=True)
    delay = 0.11 if a.api_key else 0.4
    key = f"&api_key={a.api_key}" if a.api_key else ""

    q = a.query
    if a.mindate and a.maxdate:
        q += f" AND {a.mindate}:{a.maxdate}[{a.datetype}]"
    q_enc = urllib.parse.quote(q)

    # --- esearch: 计数 + WebEnv 历史 ---
    url = f"{BASE}/esearch.fcgi?db=pubmed&term={q_enc}&retmax=0&usehistory=y{key}"
    xml = http_get(url); time.sleep(delay)
    count = int(re.search(r"<Count>(\d+)</Count>", xml).group(1))
    webenv_m = re.search(r"<WebEnv>(\S+)</WebEnv>", xml)
    qk_m = re.search(r"<QueryKey>(\d+)</QueryKey>", xml)
    print(f"命中: {count} 篇")

    pmids = []
    if webenv_m and qk_m:
        webenv, qk = webenv_m.group(1), qk_m.group(1)
        # 分批取全部 PMID
        for start in range(0, min(count, a.retmax_cap), 5000):
            url = f"{BASE}/esearch.fcgi?db=pubmed&term={q_enc}&retstart={start}&retmax=5000&usehistory=y&WebEnv={webenv}&query_key={qk}{key}"
            xml = http_get(url); time.sleep(delay)
            pmids += re.findall(r"<Id>(\d+)</Id>", xml)

    # 存 PMID
    with open(f"{a.out_dir}/pubmed_pmids.txt", "w") as f:
        f.write("\n".join(pmids))
    print(f"PMID 列表: {len(pmids)} 条 -> pubmed_pmids.txt")

    # --- efetch MEDLINE 分批 ---
    raw_parts = []
    batch = 500
    for i in range(0, len(pmids), batch):
        chunk = ",".join(pmids[i:i+batch])
        url = f"{BASE}/efetch.fcgi?db=pubmed&id={chunk}&rettype=medline&retmode=text{key}"
        raw_parts.append(http_get(url)); time.sleep(delay)
        print(f"  efetch {min(i+batch,len(pmids))}/{len(pmids)}")
    raw = "\n\n".join(raw_parts)
    with open(f"{a.out_dir}/pubmed_raw.txt", "w", encoding="utf-8") as f:
        f.write(raw)

    # --- 解析 CSV ---
    recs = parse_medline(raw)
    cols = ["pmid","doi","title","abstract","authors","journal","year","language","pubtype"]
    with open(f"{a.out_dir}/all_records.csv", "w", newline="", encoding="utf-8-sig") as f:
        w = csv.writer(f); w.writerow(cols)
        for r in recs:
            doi = ""
            for aid in [r.get("AID",""), r.get("LID","")]:
                m = re.search(r"(10\.\d{4,9}/\S+?)(?:\s*\[(?:doi|pii)\])?\s*$", aid or "")
                if m and "[pii]" not in (aid or "").replace(m.group(1), ""):
                    doi = m.group(1); break
            w.writerow([
                r.get("PMID",""), doi,
                r.get("TI","").rstrip("."),
                re.sub(r"\s+"," ", r.get("AB","")),
                "; ".join(re.findall(r"^[^,]+,", r.get("FAU","")) ) or r.get("FAU",""),
                r.get("JT",""), r.get("DP","")[:4],
                r.get("LA","eng"), "|".join(re.findall(r"(Review|Meta-Analysis|Randomized Controlled Trial|Clinical Trial|Comparative Study)", r.get("PT","")))
            ])
    print(f"题录 CSV: {len(recs)} 条 -> all_records.csv")
    print(f"原始 MEDLINE: pubmed_raw.txt ({len(raw)//1024} KB)")

if __name__ == "__main__":
    main()
