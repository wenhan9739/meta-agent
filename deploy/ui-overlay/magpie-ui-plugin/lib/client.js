// @magpie/meta-agent-ui — browser (client) half.
//
// Jobs (all client-side):
//   1. BRAND — replace the official whale-brand slots with the Evidence
//      Explorer identity (three-band blue gradient wing + greeting).
//   2. THEME — inject a stylesheet remapping the app's alias tokens to the
//      brand palette, accent the sidebar, and present the boot splash brand.
//   3. CLOUD UX — the product runs server-side over HTTPS, so the local-
//      workspace concept has no user-facing meaning:
//        - hide workspace picker rows (hero + sidebar),
//        - rewrite the hero headline to the brand greeting,
//        - rewrite the composer placeholder to invite a chat message,
//        - replace the HARNESS boot splash with logo + greeting.

window.__ModuleLoader__.load({
	id: "@magpie/meta-agent-ui",
	factory: (require) => {
		var module = { exports: {} };
		var exports = module.exports;
		Object.defineProperty(exports, Symbol.toStringTag, { value: "Module" });
		let react_jsx_runtime = require("react/jsx-runtime");

		//#region brand identity
		const BRAND_TEXT = "你好 · 证据科学探索者";
		const COMPOSER_PLACEHOLDER = "你好，我是证据科学探索者。描述你准备做的系统综述或证据问题，我们开始。";
		const SPLASH_HINT = "正在装载证据科学分析能力…";

		// Three overlapping gradient bands (wing/checkmark) in a 512 viewBox;
		// reused by the React brand mark and the boot splash.
		const LOGO_PATHS = [
			"M 190.3,463.9 L 423.0,222.9 L 342.4,145.1 L 109.7,386.1 A 56,56 0 1 0 190.3,463.9 Z",
			"M 265.8,495.1 L 498.5,254.1 L 417.9,176.3 L 185.2,417.3 A 56,56 0 1 0 265.8,495.1 Z",
			"M 341.3,526.3 L 574.0,285.3 L 493.4,207.5 L 260.7,448.5 A 56,56 0 1 0 341.3,526.3 Z"
		];
		const LOGO_GRADS = [
			["#c3f0ff", "#57d2ff"],
			["#2fb6ff", "#0a9cff"],
			["#0d7aea", "#043071"]
		];

		function logoInnerHTML(idPrefix) {
			const defs = LOGO_GRADS.map((c, i) =>
				'<linearGradient id="' + idPrefix + i + '" x1="0" y1="0" x2="1" y2="0.35">' +
				'<stop offset="0" stop-color="' + c[0] + '"/><stop offset="1" stop-color="' + c[1] + '"/></linearGradient>'
			).join("");
			const paths = LOGO_PATHS.map((d, i) =>
				'<path d="' + d + '" fill="url(#' + idPrefix + i + ')" stroke="url(#' + idPrefix + i + ')" stroke-width="16" stroke-linejoin="round" stroke-linecap="round"/>'
			).join("");
			return '<defs>' + defs + '</defs><g transform="translate(256,256) scale(0.9) translate(-341.85,-335.7)">' + paths + '</g>';
		}

		let MARK_SEQ = 0;
		function MagpieBrandMark({ size, className }) {
			const s = MARK_SEQ++;
			const gp = "mg" + s + "-";
			return (0, react_jsx_runtime.jsxs)("svg", {
				width: size, height: size, viewBox: "0 0 512 512", className, role: "img", "aria-label": BRAND_TEXT,
				children: [
					(0, react_jsx_runtime.jsxs)("defs", { children: [
						(0, react_jsx_runtime.jsxs)("linearGradient", { id: gp + "0", x1: "0", y1: "0", x2: "1", y2: "0.35", children: [
							(0, react_jsx_runtime.jsx)("stop", { offset: "0", stopColor: "#c3f0ff" }),
							(0, react_jsx_runtime.jsx)("stop", { offset: "1", stopColor: "#57d2ff" })
						] }),
						(0, react_jsx_runtime.jsxs)("linearGradient", { id: gp + "1", x1: "0", y1: "0", x2: "1", y2: "0.35", children: [
							(0, react_jsx_runtime.jsx)("stop", { offset: "0", stopColor: "#2fb6ff" }),
							(0, react_jsx_runtime.jsx)("stop", { offset: "1", stopColor: "#0a9cff" })
						] }),
						(0, react_jsx_runtime.jsxs)("linearGradient", { id: gp + "2", x1: "0", y1: "0", x2: "1", y2: "0.35", children: [
							(0, react_jsx_runtime.jsx)("stop", { offset: "0", stopColor: "#0d7aea" }),
							(0, react_jsx_runtime.jsx)("stop", { offset: "1", stopColor: "#043071" })
						] })
					] }),
					(0, react_jsx_runtime.jsxs)("g", { transform: "translate(256,256) scale(0.9) translate(-341.85,-335.7)", children: [
						(0, react_jsx_runtime.jsx)("path", { d: LOGO_PATHS[0], fill: "url(#" + gp + "0)", stroke: "url(#" + gp + "0)", strokeWidth: 16, strokeLinejoin: "round", strokeLinecap: "round" }),
						(0, react_jsx_runtime.jsx)("path", { d: LOGO_PATHS[1], fill: "url(#" + gp + "1)", stroke: "url(#" + gp + "1)", strokeWidth: 16, strokeLinejoin: "round", strokeLinecap: "round" }),
						(0, react_jsx_runtime.jsx)("path", { d: LOGO_PATHS[2], fill: "url(#" + gp + "2)", stroke: "url(#" + gp + "2)", strokeWidth: 16, strokeLinejoin: "round", strokeLinecap: "round" })
					] })
				]
			});
		}

		function MagpieBrandName() {
			return (0, react_jsx_runtime.jsxs)("span", {
				style: { display: "inline-flex", alignItems: "center", gap: 6, whiteSpace: "nowrap", lineHeight: 1.1 },
				children: (0, react_jsx_runtime.jsx)("span", {
					style: { fontSize: "1.0rem", fontWeight: 700, letterSpacing: "0.02em", color: "var(--dsh-boot-label-primary, #0f1115)" },
					children: BRAND_TEXT
				})
			});
		}
		//#endregion

		//#region theme — alias-token remap + layout accents + splash brand
		const THEME_CSS = [
			"/* === Evidence-Explorer theme overlay (@magpie/meta-agent-ui) === */",
			"html body {",
			"  --dsw-alias-button-primary-fill: #0d7aea;",
			"  --dsw-alias-button-primary-fill-hover: #0b63bd;",
			"  --dsw-alias-label-primary-foreground: #ffffff;",
			"  --dsw-alias-state-business-primary: #0d7aea;",
			"  --magpie-blue: #0a9cff;",
			"  --magpie-deep: #043071;",
			"}",
			"/* sidebar: soft brand tint (light) */",
			"html body [class*=\"_sidebarCol\"] { background: linear-gradient(180deg, #f4faff 0%, #eef7ff 100%); }",
			"/* sidebar: brand-blue selected-session accent */",
			"html body [class*=\"_sidebarCol\"] [class*=\"_sessionRow\"][aria-selected=\"true\"],",
			"html body [class*=\"_sidebarCol\"] [class*=\"_item\"][aria-selected=\"true\"] { box-shadow: inset 2px 0 0 #0a9cff; }",
			"/* hero composer card: soft brand glow */",
			"html body [class*=\"_composerStack\"] { --dsw-hovercard-bg: #ffffff; }",
			"/* dark mode sidebar */",
			"html body[data-ds-dark-theme] [class*=\"_sidebarCol\"] { background: linear-gradient(180deg, #0e1420 0%, #0c1119 100%); }",
			"/* === boot splash brand === */",
			"html body .magpie-boot-brand { display:flex; flex-direction:column; align-items:center; gap:14px; line-height:1.1; }",
			"html body .magpie-boot-brand svg { width:88px; height:88px; }",
			"html body .magpie-boot-label { font-size:20px; font-weight:700; letter-spacing:.02em; color:#0f1115; white-space:nowrap; }",
			"html body[data-ds-dark-theme] .magpie-boot-label { color:#edf2f7; }",
			"/* === cloud UX: no local-workspace concept on the web product === */",
			"html body [class*=\"_heroWorkspaceRow\"] { display: none !important; }",
			"html body [class*=\"_sidebarCol\"] [class*=\"_sectionHeader\"] { display: none !important; }",
			"html body [class*=\"_previewBadge\"] { display: none !important; }"
		].join("\n");

		/** Install the theme <style>. Idempotent across HMR reloads. */
		function injectTheme() {
			if (document.getElementById("magpie-theme")) return;
			const el = document.createElement("style");
			el.id = "magpie-theme";
			el.textContent = THEME_CSS;
			(document.head || document.documentElement).appendChild(el);
		}
		//#endregion

		//#region boot splash brand — replace the HARNESS wordmark on first paint
		function bootBrandHTML() {
			return '<div class="magpie-boot-brand">' +
				'<svg width="88" height="88" viewBox="0 0 512 512" role="img" aria-label="' + BRAND_TEXT + '">' + logoInnerHTML("magpie-boot-") + '</svg>' +
				'<div class="magpie-boot-label">' + BRAND_TEXT + '</div>' +
				'</div>';
		}
		function installSplashBrand() {
			function applyOnce() {
				const spinner = document.querySelector("[data-dsh-boot-spinner]");
				if (!spinner) return false;
				let card = null;
				for (let n = spinner; n && n !== document.body && n !== document.documentElement; n = n.parentElement) {
					if (n.textContent && /HARNESS/i.test(n.textContent) && /Loading plugins/i.test(n.textContent)) { card = n; break; }
				}
				if (!card) return false;
				let wordEl = null;
				const w = document.createTreeWalker(card, NodeFilter.SHOW_TEXT);
				let cur;
				while ((cur = w.nextNode())) {
					if (cur.nodeType === Node.TEXT_NODE && /HARNESS/i.test(cur.textContent)) { wordEl = cur.parentElement; break; }
				}
				if (wordEl && !wordEl.querySelector(".magpie-boot-brand")) {
					wordEl.style.display = "block";
					wordEl.style.textAlign = "center";
					wordEl.textContent = "";
					wordEl.innerHTML = bootBrandHTML();
				}
				const hw = document.createTreeWalker(card, NodeFilter.SHOW_TEXT);
				let hn;
				while ((hn = hw.nextNode())) {
					if (hn.nodeType === Node.TEXT_NODE && /Loading plugins/i.test(hn.textContent)) hn.textContent = SPLASH_HINT;
				}
				return true;
			}
			const obs = new MutationObserver(applyOnce);
			obs.observe(document.body || document.documentElement, { childList: true, subtree: true, characterData: true });
			applyOnce();
		}
		//#endregion

		//#region hero copy — brand greeting + composer chat placeholder
		function rewriteHeroText(node) {
			if (node.nodeType !== Node.TEXT_NODE) return;
			const t = node.textContent;
			if (t && t.includes("探索未至之境")) node.textContent = t.split("探索未至之境").join(BRAND_TEXT);
		}
		function installHeroRewrite() {
			const obs = new MutationObserver((mutations) => {
				for (const m of mutations) {
					if (m.type === "characterData") rewriteHeroText(m.target);
					for (const n of m.addedNodes) {
						rewriteHeroText(n);
						if (n.nodeType === Node.ELEMENT_NODE) {
							const walker = document.createTreeWalker(n, NodeFilter.SHOW_TEXT);
							let cur;
							while ((cur = walker.nextNode())) rewriteHeroText(cur);
						}
					}
				}
			});
			const start = () => obs.observe(document.body || document.documentElement, {
				childList: true, subtree: true, characterData: true
			});
			if (document.body) {
				start();
				const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
				let cur;
				while ((cur = walker.nextNode())) rewriteHeroText(cur);
			} else {
				document.addEventListener("DOMContentLoaded", start, { once: true });
			}
		}
		function installComposerRewrite() {
			function rewrite() {
				document.querySelectorAll('textarea[placeholder="选择一个工作区开始"], [contenteditable="true"][data-placeholder="选择一个工作区开始"], [data-placeholder="选择一个工作区开始"]').forEach((el) => {
					el.setAttribute("placeholder", COMPOSER_PLACEHOLDER);
					el.setAttribute("data-placeholder", COMPOSER_PLACEHOLDER);
				});
				const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
				let n;
				while ((n = walker.nextNode())) {
					if (n.nodeType === Node.TEXT_NODE && n.textContent.includes("选择一个工作区开始")) {
						n.textContent = n.textContent.split("选择一个工作区开始").join(COMPOSER_PLACEHOLDER);
					}
				}
			}
			const obs = new MutationObserver(rewrite);
			obs.observe(document.body || document.documentElement, { childList: true, subtree: true, attributes: true, attributeFilter: ["placeholder", "data-placeholder"] });
			rewrite();
		}
		//#endregion

		//#region slot registration
		/** Required service: the UI slot registry. */
		const inject = ["slots"];
		function apply(ctx) {
			ctx.slots.inject("sidebar.brand.mark", () => ctx.slots.inject("sidebar.brand.name", () => ctx.slots.inject("conversation.hero.brand.mark", function* () {
				yield ctx.slots.register({ name: "sidebar.brand.mark" }, MagpieBrandMark);
				yield ctx.slots.register({ name: "sidebar.brand.name" }, MagpieBrandName);
				yield ctx.slots.register({ name: "conversation.hero.brand.mark" }, MagpieBrandMark);
			})));
		}
		//#endregion

		// module-load side effects: brand + theme are presentation facts
		// independent of the slot registry lifecycle.
		injectTheme();
		installSplashBrand();
		installHeroRewrite();
		installComposerRewrite();

		exports.apply = apply;
		exports.inject = inject;
		return module.exports;
	}
});
