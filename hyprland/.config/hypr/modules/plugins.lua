-- Hyprland plugin loading.
--
-- THE MODEL (measured 2026-07-28 — see docs/problems.md → "hyprglass"):
--
--   * `hl.plugin.load()` does NOT work on 0.56.0. It returns success while the
--     plugin never loads, so it can't be used and can't even be error-checked.
--     Loading is done by hyprpm instead.
--   * hyprpm runs AFTER this config is parsed, so on a cold start every
--     `if hl.plugin.<name>` guard is false and no plugin config applies. We
--     therefore re-parse once hyprpm has finished.
--   * `hyprctl reload` keeps plugins loaded but resets all their options to
--     defaults — which is why theme/glass.lua must always be written, including
--     an explicit disable stub for themes that don't want glass. Without it
--     hyprglass defaults to enabled and every theme gets glass.
--
-- `config-only` keeps this off the monitor path: monitor rules only take effect
-- at output connect, and there's no reason to re-run that dance on every login.
-- See modules/monitors.lua.
--
-- Enable/disable a plugin with `hyprpm enable|disable <name>`; that state lives
-- outside this repo, in /var/cache/hyprpm/$USER/. Per-plugin *appearance* config
-- is theme-owned (theme/glass.lua); anything behavioural would get its own module.

hl.on("hyprland.start", function()
	hl.exec_cmd("hyprpm reload -n && hyprctl reload config-only")
end)
