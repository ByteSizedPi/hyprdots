local M = {}

function M.setup()
	require("base16-colorscheme").setup({
		base00 = "{{colors.surface.default.hex}}",
		base01 = "{{colors.surface_container.default.hex}}",
		base02 = "{{colors.surface_container_high.default.hex}}",
		base03 = "{{colors.outline.default.hex}}",
		base04 = "{{colors.on_surface_variant.default.hex}}",
		base05 = "{{colors.on_surface.default.hex}}",
		base06 = "{{colors.on_surface.default.hex}}",
		base07 = "{{colors.on_background.default.hex}}",
		base08 = "{{colors.error.default.hex}}",
		base09 = "{{colors.tertiary.default.hex}}",
		base0A = "{{colors.secondary.default.hex}}",
		base0B = "{{colors.primary.default.hex}}",
		base0C = "{{colors.tertiary_fixed_dim.default.hex}}",
		base0D = "{{colors.primary_fixed_dim.default.hex}}",
		base0E = "{{colors.secondary_fixed_dim.default.hex}}",
		base0F = "{{colors.error_container.default.hex}}",
	})

	local hi = function(group, opts)
		vim.api.nvim_set_hl(0, group, opts)
	end

	hi("WinSeparator", { fg = "{{colors.outline.default.hex}}", bg = "{{colors.surface.default.hex}}" })

	-- base16 maps Visual to base02 (surface_container_high), which sits at 1.15:1
	-- against the surface and is unreadable. Use kitty's inverted selection instead
	-- (17.2:1). The explicit fg is required: on a light bg the syntax colors that
	-- base16 leaves showing through are unreadable. Kept in sync with
	-- text_selected in templates/zellij-theme.kdl and selection_* in kitty-theme.conf.
	hi("Visual", { fg = "{{colors.surface.default.hex}}", bg = "{{colors.on_surface.default.hex}}" })

	hi("TelescopeNormal", { fg = "{{colors.on_surface.default.hex}}", bg = "{{colors.surface.default.hex}}" })
	hi("TelescopeBorder", { fg = "{{colors.outline.default.hex}}", bg = "{{colors.surface.default.hex}}" })
	hi("TelescopePromptNormal", {
		fg = "{{colors.on_surface.default.hex}}",
		bg = "{{colors.surface.default.hex}}",
	})
	hi("TelescopePromptBorder", {
		fg = "{{colors.outline.default.hex}}",
		bg = "{{colors.surface.default.hex}}",
	})
	hi("TelescopePromptPrefix", {
		fg = "{{colors.primary.default.hex}}",
		bg = "{{colors.surface.default.hex}}",
	})
	hi(
		"TelescopePromptCounter",
		{ fg = "{{colors.on_surface_variant.default.hex}}", bg = "{{colors.surface.default.hex}}" }
	)
	hi("TelescopePromptTitle", {
		fg = "{{colors.surface.default.hex}}",
		bg = "{{colors.primary.default.hex}}",
	})
	hi("TelescopePreviewTitle", {
		fg = "{{colors.surface.default.hex}}",
		bg = "{{colors.secondary.default.hex}}",
	})
	hi("TelescopeResultsTitle", {
		fg = "{{colors.surface.default.hex}}",
		bg = "{{colors.tertiary.default.hex}}",
	})
	hi(
		"TelescopeSelection",
		{ fg = "{{colors.on_surface.default.hex}}", bg = "{{colors.surface_container_high.default.hex}}" }
	)
	hi(
		"TelescopeSelectionCaret",
		{ fg = "{{colors.primary.default.hex}}", bg = "{{colors.surface_container_high.default.hex}}" }
	)
	hi("TelescopeMatching", { fg = "{{colors.primary.default.hex}}", bold = true })

	-- Bufferline links to these groups so DevIcon bgs are generated correctly
	hi("NoctaliaTabFill", { bg = "{{colors.surface.default.hex}}" })
	hi(
		"NoctaliaTabInactive",
		{ fg = "{{colors.on_surface_variant.default.hex}}", bg = "{{colors.surface_container.default.hex}}" }
	)
	hi(
		"NoctaliaTabVisible",
		{ fg = "{{colors.on_surface_variant.default.hex}}", bg = "{{colors.surface_container.default.hex}}" }
	)
	hi("NoctaliaTabSelected", {
		fg = "{{colors.surface.default.hex}}",
		bg = "{{colors.primary.default.hex}}",
	})

	-- vim.notify("Noctalia: theme applied", vim.log.levels.INFO)
end

return M
