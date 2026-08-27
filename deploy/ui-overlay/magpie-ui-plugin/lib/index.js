// @magpie/meta-agent-ui — host (node) half.
// The bundle patch (cordis.patch.yml) carries all host-side wiring; the node
// face of this package exists so the patch row can reference it as a bundle
// dependency that resolves cleanly under pnpm.
/** Host plugin body — browser presentation lives in ./client. */
function apply() {}
export { apply };
