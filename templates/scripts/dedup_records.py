#!/usr/bin/env python3
# ============================================================
# dedup_records.py — 跨库题录去重 (PRISMA 去重步骤)
# 输入: 一个或多个 records CSV (列须含 pmid,doi,title; 可选 source_db)
# 规则: DOI(归一) → PMID → 标题归一化精确匹配
# 用法: python dedup_records.py --inputs 10-search/all_records.csv other.csv \
#         --out-dir 10-search
# 产物: unique_records.csv, duplicates.csv, dedup_log.md
# ============================================================
import argparse, csv, hashlib, os, re, sys, unicodedata

def norm_title(t):
    t = unicodedata.normalize("NFKD", t or "").lower()
    t = re.sub(r"[^a-z0-9 ]", "", t)
    return re.sub(r"\s+", " ", t).strip()

def norm_doi(d):
    d = (d or "").strip().lower()
    return d[4:] if d.startswith("https://doi.org/") else d

def human_db_name(file_stem):
    """把文件名残片映射为可读的数据库名，供 source_db 与 PRISMA 计数表使用。
    例: all_records -> PubMed, central_records -> CENTRAL, embase_records -> Embase。
    若记录自带 source_db（如 CENTRAL 记录已写入 source_db 列），则以记录值为准。"""
    mapping = {
        "all_records": "PubMed",
        "central_records": "CENTRAL",
        "embase_records": "Embase",
        "scopus_records": "Scopus",
        "wos_records": "Web of Science",
        "cinahl_records": "CINAHL",
        "webofscience_records": "Web of Science",
    }
    key = file_stem.replace("_records", "")
    return mapping.get(file_stem, key if key else file_stem)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--inputs", nargs="+", required=True)
    ap.add_argument("--out-dir", default=".")
    a = ap.parse_args()
    os.makedirs(a.out_dir, exist_ok=True)

    rows, per_db = [], {}
    for path in a.inputs:
        stem = os.path.splitext(os.path.basename(path))[0]
        db = stem.replace("_records","")
        label = human_db_name(stem)
        with open(path, encoding="utf-8-sig") as f:
            for r in csv.DictReader(f):
                r.setdefault("source_db", label)
                r["_db_file"] = db
                rows.append(r)
                per_db[label] = per_db.get(label, 0) + 1
    print(f"合计读入 {len(rows)} 条: {per_db}")

    seen_doi, seen_pmid, seen_title = {}, {}, {}
    uniq, dups = [], []
    for r in rows:
        rid = f'{r.get("_db_file","?")}:{r.get("pmid", r.get("PMID",""))}'
        doi, pmid, tt = norm_doi(r.get("doi", r.get("DOI",""))), str(r.get("pmid", r.get("PMID","")) or ""), norm_title(r.get("title", r.get("Title","")))
        reason = None
        if doi and doi in seen_doi: reason = f"DOI duplicate of {seen_doi[doi]}"
        elif pmid and pmid in seen_pmid: reason = f"PMID duplicate of {seen_pmid[pmid]}"
        elif tt and len(tt) > 20 and tt in seen_title: reason = f"title duplicate of {seen_title[tt]}"
        if reason:
            dups.append({**{k: r.get(k,"") for k in ("source_db","pmid","PMID","doi","DOI","title","Title")}, "_reason": reason})
        else:
            if doi: seen_doi[doi] = rid
            if pmid: seen_pmid[pmid] = rid
            if tt and len(tt) > 20: seen_title[tt] = rid
            uniq.append(r)

    # 统一列名输出
    def pick(r):
        out = {
            "pmid": r.get("pmid", r.get("PMID","")),
            "doi": r.get("doi", r.get("DOI","")),
            "title": r.get("title", r.get("Title","")),
            "abstract": r.get("abstract", r.get("Abstract","")),
            "authors": r.get("authors",""),
            "journal": r.get("journal",""),
            "year": r.get("year",""),
            "pubtype": r.get("pubtype",""),
            "source_db": r.get("source_db", r.get("_db_file","")),
            "local_pdf": "",
            "central_id": r.get("central_id", ""),
            "source": r.get("source", ""),
            "url": r.get("url", ""),
        }
        return out
    pick_fields = list(pick(uniq[0]).keys()) if uniq else ["pmid"]
    with open(f"{a.out_dir}/unique_records.csv","w",newline="",encoding="utf-8-sig") as f:
        w = csv.DictWriter(f, fieldnames=pick_fields); w.writeheader()
        for r in uniq: w.writerow(pick(r))
    with open(f"{a.out_dir}/duplicates.csv","w",newline="",encoding="utf-8-sig") as f:
        w = csv.DictWriter(f, fieldnames=["source_db","pmid","doi","title","_reason"]); w.writeheader()
        for d in dups:
            w.writerow({"source_db":d.get("source_db"),"pmid":d.get("pmid",d.get("PMID","")),
                        "doi":d.get("doi",d.get("DOI","")),"title":(d.get("title")or"")[:120],"_reason":d["_reason"]})

    # PRISMA 计数片段
    kept_per = {}
    for r in uniq: kept_per[r.get("source_db", r.get("_db_file",""))] = kept_per.get(r.get("source_db", r.get("_db_file","")),0)+1
    with open(f"{a.out_dir}/dedup_log.md","w",encoding="utf-8") as f:
        f.write("# 去重记录 (PRISMA identification→screening)\n\n| 来源 | 读入 | 保留 |\n|---|---|---|\n")
        for db in per_db: f.write(f"| {db} | {per_db[db]} | {kept_per.get(db,'-')} |\n")
        f.write(f"| **合计** | **{len(rows)}** | **{len(uniq)}** |\n\n去重移除: **{len(dups)}**\n")
        f.write("\n规则顺序: DOI 归一匹配 → PMID → 标题归一化(NFKD小写去标点)\n")
    print(f"唯一记录 {len(uniq)} | 去重 {len(dups)} -> unique_records.csv / duplicates.csv / dedup_log.md")

if __name__ == "__main__":
    main()
