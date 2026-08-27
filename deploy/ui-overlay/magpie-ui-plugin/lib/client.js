// @magpie/meta-agent-ui — browser (client) half.
//
// Three jobs, all client-side (no host wiring needed):
//   1. BRAND — fill the same slots the official whale-brand plugin fills
//      (sidebar mark/name, hero mark) with MAGPIE identity. Shadowing
//      election makes dynamic registrations win over shipped ones.
//   2. THEME — inject a stylesheet that remaps the app's alias design
//      tokens to the MAGPIE palette and applies the Dr.Magpie-inspired
//      layout accents. Injected as a plain <style> in document.head with
//      an `html body` selector so it wins cascade order battles against
//      the app's constructable stylesheets regardless of insertion order.
//   3. CLOUD UX — this deployment serves remote browsers over HTTPS; the
//      agent runs server-side in its own container. The local-workspace
//      directory concept therefore has no user-facing meaning:
//        - hide the workspace picker rows (hero + sidebar),
//        - rewrite the hero headline for the Meta-Agent vertical,
//        - hide the preview badge (white-label product, not a preview).
//      File upload stays on the composer's attachment affordance; produced
//      files surface through the turn deliverables chips.

window.__ModuleLoader__.load({
	id: "@magpie/meta-agent-ui",
	factory: (require) => {
		var module = { exports: {} };
		var exports = module.exports;
		Object.defineProperty(exports, Symbol.toStringTag, { value: "Module" });
		let react_jsx_runtime = require("react/jsx-runtime");

		//#region 1. brand components — the magpie wing, inline SVG
		/**
		 * Render the MAGPIE mark at the size its host surface requests.
		 * Inline SVG keeps the mark self-contained: no asset round-trip,
		 * crisp at every DPI, works in dark mode unmodified.
		 */
		function MagpieBrandMark({ size, className }) {
			return (0, react_jsx_runtime.jsx)(
				"svg",
				{
					width: size,
					height: size,
					viewBox: "0 0 200 200",
					className,
					"aria-label": "MAGPIE",
					role: "img",
					children: (0, react_jsx_runtime.jsxs)("g", {
						children: [
							(0, react_jsx_runtime.jsx)("circle", { cx: 100, cy: 100, r: 95, fill: "#09a7fe", opacity: 0.08 }),
							(0, react_jsx_runtime.jsx)("path", {
								d: "M60,130 C60,130 70,80 100,55 C110,48 125,45 130,50 C135,55 125,70 115,85 C105,100 95,120 90,135 C85,145 70,140 60,130 Z",
								fill: "#a2eefd",
								opacity: 0.9
							}),
							(0, react_jsx_runtime.jsx)("path", {
								d: "M75,125 C80,90 95,60 120,45 C130,40 145,42 148,50 C151,58 142,72 132,88 C122,104 110,125 105,140 C100,150 85,138 75,125 Z",
								fill: "#09a7fe",
								opacity: 0.95
							}),
							(0, react_jsx_runtime.jsx)("path", {
								d: "M90,120 C98,85 115,55 145,42 C155,38 168,40 170,50 C172,60 162,75 150,92 C138,109 125,130 120,145 C115,155 100,135 90,120 Z",
								fill: "#064fab"
							}),
							(0, react_jsx_runtime.jsx)("path", {
								d: "M85,115 C90,85 108,58 135,46",
								stroke: "white",
								strokeWidth: 1.5,
								fill: "none",
								opacity: 0.4,
								strokeLinecap: "round"
							}),
							(0, react_jsx_runtime.jsx)("circle", { cx: 155, cy: 55, r: 3, fill: "#c8faff", opacity: 0.6 }),
							(0, react_jsx_runtime.jsx)("circle", { cx: 165, cy: 65, r: 2, fill: "#09a7fe", opacity: 0.4 })
						]
					})
				}
			);
		}

		/**
		 * MAGPIE wordmark: product name + Meta-Agent chip, replacing the
		 * official "deepseek HARNESS" identity in the sidebar header.
		 * Colors are literal (not tokens) so they hold in light and dark.
		 */
		function MagpieBrandName() {
			return (0, react_jsx_runtime.jsxs)(
				"span",
				{
					style: {
						display: "inline-flex",
						alignItems: "baseline",
						gap: 6,
						whiteSpace: "nowrap",
						lineHeight: 1.1
					},
					children: [
						(0, react_jsx_runtime.jsx)(
							"span",
							{
								style: {
									fontSize: "1.02rem",
									fontWeight: 700,
									letterSpacing: "0.02em",
									color: "var(--dsh-boot-label-primary, #0f1115)"
								},
								children: "MAGPIE"
							}
						),
						(0, react_jsx_runtime.jsx)(
							"span",
							{
								style: {
									fontSize: "0.58rem",
									fontWeight: 600,
									letterSpacing: "0.14em",
									padding: "2px 6px",
									borderRadius: 4,
									color: "#09a7fe",
									background: "rgba(9,167,254,0.12)",
									border: "1px solid rgba(9,167,254,0.25)",
									textTransform: "uppercase"
								},
								children: "Meta-Agent"
							}
						)
					]
				}
			);
		}
		//#endregion

		//#region 2. theme — alias-token remap + layout accents
		/**
		 * The app defines its palette through constructable stylesheets
		 * (adoptedStyleSheets), so a document stylesheet with an `html body`
		 * (higher-specificity) selector wins for every inherited custom
		 * property no matter which sheet came last. Layout rules target
		 * hashed-module class SUFFIXES (semantic, stable across rebuilds):
		 * `_heroWorkspaceRow`, `_sectionHeader`, `_previewBadge`,
		 * `_sidebarCol`.
		 */
		const THEME_CSS = [
			"/* === MAGPIE theme overlay (@magpie/meta-agent-ui) === */",
			"html body {",
			"  /* primary action + brand accent -> MAGPIE deep blue */",
			"  --dsw-alias-button-primary-fill: #064fab;",
			"  --dsw-alias-button-primary-fill-hover: #054699;",
			"  --dsw-alias-label-primary-foreground: #ffffff;",
			"  --dsw-alias-state-business-primary: #064fab;",
			"  --magpie-blue: #09a7fe;",
			"  --magpie-deep: #064fab;",
			"}",
			"/* sidebar: Dr.Magpie-style tinted left rail (light) */",
			"html body [class*=\"_sidebarCol\"] {",
			"  background: linear-gradient(180deg, #f7fbff 0%, #f1f8ff 100%);",
			"}",
			"/* sidebar: magpie-blue selected-session accent */",
			"html body [class*=\"_sidebarCol\"] [class*=\"_sessionRow\"][aria-selected=\"true\"],",
			"html body [class*=\"_sidebarCol\"] [class*=\"_item\"][aria-selected=\"true\"] {",
			"  box-shadow: inset 2px 0 0 #09a7fe;",
			"}",
			"/* hero composer card: soft brand glow */",
			"html body [class*=\"_composerStack\"] {",
			"  --dsw-hovercard-bg: #ffffff;",
			"}",
			"/* dark mode sidebar */",
			"html body[data-ds-dark-theme] [class*=\"_sidebarCol\"] {",
			"  background: linear-gradient(180deg, #0e1420 0%, #0c1119 100%);",
			"}",
			"/* === cloud UX: no local-workspace concept on the web product === */",
			"/* hero workspace picker row (选择工作区 + 模式 pills row) */",
			"html body [class*=\"_heroWorkspaceRow\"] { display: none !important; }",
			"/* sidebar 工作区 section header (label + search + add-workspace icons);",
			"   the session tree below stays visible */",
			"html body [class*=\"_sidebarCol\"] [class*=\"_sectionHeader\"] { display: none !important; }",
			"/* preview badge — white-label product */",
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

		//#region 3. cloud UX copy — hero headline rewrite
		/**
		 * The hero headline ("探索未至之境") is React-rendered text inside
		 * `_headlineText`; a MutationObserver rewrites it as it appears and
		 * re-asserts after app re-renders. Text-node-level replacement only —
		 * never touches React state, so reconciliation stays consistent.
		 */
		const HERO_TITLE = "系统综述 · Meta分析智能体";

		function rewriteHeroText(node) {
			if (node.nodeType !== Node.TEXT_NODE) return;
			const t = node.textContent;
			if (t && t.includes("探索未至之境")) node.textContent = t.split("探索未至之境").join(HERO_TITLE);
		}

		function installHeroRewrite() {
			const obs = new MutationObserver((mutations) => {
				for (const m of mutations) {
					if (m.type === "characterData") rewriteHeroText(m.target);
					for (const n of m.addedNodes) {
						rewriteHeroText(n);
						if (n.nodeType === Node.ELEMENT_NODE) {
							// catch newly-added subtree text (React mounts whole trees)
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
				// sweep whatever already exists
				const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
				let cur;
				while ((cur = walker.nextNode())) rewriteHeroText(cur);
			} else {
				document.addEventListener("DOMContentLoaded", start, { once: true });
			}
		}
		//#endregion

		//#region slot registration
		/** Required service: the UI slot registry. */
		const inject = ["slots"];
		/**
		 * Fill the three shipped brand slots (same contract as the official
		 * brand plugin). Election: our dynamic registrations shadow the
		 * shipped entries; the official plugin is additionally disabled at
		 * the bundle-patch layer so its slots sit empty for us alone.
		 */
		function apply(ctx) {
			ctx.slots.inject("sidebar.brand.mark", () => ctx.slots.inject("sidebar.brand.name", () => ctx.slots.inject("conversation.hero.brand.mark", function* () {
				yield ctx.slots.register({ name: "sidebar.brand.mark" }, MagpieBrandMark);
				yield ctx.slots.register({ name: "sidebar.brand.name" }, MagpieBrandName);
				yield ctx.slots.register({ name: "conversation.hero.brand.mark" }, MagpieBrandMark);
			})));
		}
		//#endregion

		// module-load side effects: theme + hero copy are presentation facts
		// independent of the slot registry lifecycle.
		injectTheme();
		installHeroRewrite();

		exports.apply = apply;
		exports.inject = inject;
		return module.exports;
	}
});
