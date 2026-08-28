#!/usr/bin/env python3
# ============================================================
# central_search.py — CENTRAL (Cochrane Central Register of Controlled Trials) 自动检索
# 方案: 本机 Playwright + 系统 Chrome/Edge (住宅 IP 通过 Cloudflare/Turnstile)
# 用法:
#   python central_search.py --query 'copd AND "inhaled corticosteroid"' \
#     --pages 3 --out-dir projects/<slug>/10-search
#   python central_search.py --query-file query_central.txt --pages 3 \
#     --out-dir projects/<slug>/10-search
# 产物: central_records.csv (pmid/doi/title/authors/year/source_db/source/central_id/url)
# 依赖: pip install playwright  (浏览器用系统 Chrome/Edge, 无需下载 chromium)
# 注意: CENTRAL 是检索式索引而非原始数据库，最终纳入仍需回溯原文；本脚本用于补检与去重计数。
# ============================================================
import argparse, csv, os, re, sys, time, urllib.parse

def log(*a):
    print(*a, file=sys.stderr, flush=True)

def extract_items(page):
    """从当前搜索结果页提取记录。Cochrane 结果项选择器以 .search-results-item 为主。"""
    items = page.query_selector_all(".search-results-item")
    if not items:
        items = page.query_selector_all("article.search-results-item")
    recs = []
    for it in items:
        title_el = it.query_selector("h3 a, .result-title a, a.result-title")
        title = title_el.inner_text().strip() if title_el else ""
        href = title_el.get_attribute("href") if title_el else ""
        # 元信息行: 作者/年份/来源
        meta = it.query_selector(".search-result-metadata, .result-metadata, .search-result-details")
        meta_txt = meta.inner_text().strip() if meta else ""
        # DOI/PMID 链接
        doi = pmid = ""
        for a in it.query_selector_all("a"):
            t = a.get_attribute("href") or ""
            if "doi.org" in t:
                doi = t.split("doi.org/")[-1]
            m = re.search(r"pubmed/(\d+)", t)
            if m:
                pmid = m.group(1)
        recs.append({"title": title, "meta": meta_txt, "href": href, "doi": doi, "pmid": pmid})
    return recs

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--query", help="CENTRAL 检索式 (Cochrane 语法, 如 copd AND inhaled corticosteroid)")
    ap.add_argument("--query-file", help="从文件读取检索式（避免 shell 引号转义问题，与 pubmed_search.py 一致）")
    ap.add_argument("--pages", type=int, default=1, help="抓取页数 (每页约 10 条)")
    ap.add_argument("--out-dir", default="./10-search")
    ap.add_argument("--wait", type=int, default=90, help="等待 Turnstile/结果加载的最大秒数")
    ap.add_argument("--headful", action="store_true", help="显示浏览器窗口 (默认 headless，见下方 Cloudflare 警告)")
    ap.add_argument("--channel", default="msedge", help="浏览器通道: msedge(推荐,过CF最稳) | chrome")
    a = ap.parse_args()

    if not a.query and not a.query_file:
        ap.error("必须提供 --query 或 --query-file 之一")
    if a.query_file:
        with open(a.query_file, encoding="utf-8") as f:
            a.query = f.read().strip()

    from playwright.sync_api import sync_playwright
    os.makedirs(a.out_dir, exist_ok=True)
    q = urllib.parse.quote(a.query)
    url = f"https://www.cochranelibrary.com/central/search?q={q}"

    def click_turnstile(page):
        """点击 Turnstile checkbox: 优先 frame 内 input, 退回 frame 中心真实鼠标点击"""
        for f in page.frames:
            if "turnstile" in (f.url or "") or "challenges.cloudflare.com" in (f.url or ""):
                for sel in ["input[type=checkbox]", ".ctp-checkbox-label", "label", "#challenge-stage"]:
                    try:
                        el = f.query_selector(sel)
                        if el:
                            el.click(timeout=2000)
                            return True
                    except Exception:
                        pass
                try:
                    fel = f.frame_element()
                    box = fel.bounding_box()
                    if box and box["width"] > 50:
                        page.mouse.click(box["x"] + box["width"] / 2, box["y"] + box["height"] / 2)
                        return True
                except Exception:
                    pass
        return False

    def in_challenge(page):
        t = page.title()
        return ("Just a moment" in t or "安全验证" in t or "challenge" in page.url.lower())

    def pass_challenge(page, wait):
        """等待 Cloudflare/Turnstile: 先纯等自动通过, 60s 后开始点击, 最多 wait 秒"""
        t0 = time.time(); clicked = 0
        while time.time() - t0 < wait:
            if not in_challenge(page):
                return True
            if time.time() - t0 > 45 and clicked < 4:
                if click_turnstile(page):
                    clicked += 1
                    log("    Turnstile checkbox 已点击, 等待判定...")
            time.sleep(3)
        return not in_challenge(page)

    all_recs = []
    with sync_playwright() as p:
        # 注意: 必须 headful (Cloudflare 对 headless 直接拦截); Edge 过 Turnstile 成功率最高
        headless = not a.headful
        if headless:
            log("[!] headless 模式 Cloudflare 基本必拦, 建议加 --headful 用真实桌面浏览器")
        browser = p.chromium.launch(channel=a.channel, headless=headless,
                                    args=["--disable-blink-features=AutomationControlled",
                                          "--no-proxy-server"])  # 直连住宅 IP, 绕过 Clash
        ctx = browser.new_context(
            user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36",
            viewport={"width": 1440, "height": 900}, locale="en-US")
        ctx.add_init_script("Object.defineProperty(navigator,'webdriver',{get:()=>undefined})")
        page = ctx.new_page()
        # 先过首页挑战, 拿到 cf_clearance cookie 后搜索页免验证
        log("[1] 访问 cochranelibrary.com 首页 (过 Cloudflare)...")
        page.goto("https://www.cochranelibrary.com/", wait_until="domcontentloaded", timeout=60000)
        if pass_challenge(page, a.wait):
            log("    首页挑战通过 OK")
        else:
            log("[!] 首页挑战超时, 继续尝试搜索页...")
        log(f"[2] 打开 {url}")
        page.goto(url, wait_until="domcontentloaded", timeout=60000)
        pass_challenge(page, a.wait)

        # 抓取结果数
        count_el = page.query_selector(".search-results-count, .search-summary, .result-count")
        if count_el:
            log(f"[2] {count_el.inner_text().strip()}")
        log(f"[3] 开始抓取 {a.pages} 页...")
        try:
            page.wait_for_selector(".search-results-item", timeout=30000)
        except Exception as e:
            log(f"[!] 未等到结果项: {e}")
            page.screenshot(path=f"{a.out_dir}/central_debug.png")
            txt = page.inner_text("body")[:800].replace("\n", " | ")
            log(f"    URL: {page.url}")
            log(f"    页面标题: {page.title()}")
            log(f"    body: {txt}")
            browser.close()
            sys.exit(1)
        for pg in range(a.pages):
            page.wait_for_selector(".search-results-item", timeout=30000)
            recs = extract_items(page)
            log(f"    第 {pg+1} 页: {len(recs)} 条")
            for r in recs:
                r["page"] = pg + 1
            all_recs += recs
            if pg < a.pages - 1:
                # 尝试翻页: 点击 Next 按钮
                nxt = page.query_selector("a.pagination__next, .next a, a[rel='next'], button:has-text('Next')")
                if nxt:
                    nxt.click()
                    page.wait_for_timeout(4000)
                else:
                    log("    没有找到 Next 按钮, 停止翻页")
                    break
        browser.close()

    # 解析 meta 行 -> 字段
    rows = []
    for r in all_recs:
        meta = r["meta"]
        year = ""
        m = re.search(r"\b(19|20)\d{2}\b", meta)
        if m: year = m.group(0)
        source = ""
        for s in ("ClinicalTrials.gov", "PubMed", "Embase", "CINAHL", "ICTRP", "WHO"):
            if s.lower() in meta.lower():
                source = s; break
        central_id = ""
        m = re.search(r"CENTRAL[:#]?\s*(\d+)", meta)
        if m: central_id = m.group(1)
        rows.append({
            "pmid": r["pmid"],
            "doi": r["doi"],
            "title": r["title"],
            "authors": meta.split("\n")[0] if meta else "",
            "journal": "",
            "year": year,
            "source_db": "CENTRAL",
            "source": source,
            "central_id": central_id,
            "url": r["href"] if r["href"].startswith("http") else ("https://www.cochranelibrary.com" + r["href"] if r["href"] else ""),
            "abstract": "",
            "language": "",
            "pubtype": "",
        })

    out = f"{a.out_dir}/central_records.csv"
    fields = ["pmid", "doi", "title", "abstract", "authors", "journal", "year", "language",
              "pubtype", "source_db", "source", "central_id", "url"]
    with open(out, "w", newline="", encoding="utf-8-sig") as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        w.writerows(rows)
    log(f"[4] 完成: {len(rows)} 条 -> {out}")
    if not rows:
        log("    (0 条 —— 检查 central_debug.png 与 body 文本)")

if __name__ == "__main__":
    main()
