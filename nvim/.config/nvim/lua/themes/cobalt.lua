-- Fixed "cobalt" base16 theme — hand-authored, matched to kitty's "Cobalt Neon".
-- This is a TRACKED source. On a server, scripts/apply-server-theme.sh copies it to
-- lua/noctalia-theme.lua (a gitignored, per-machine output) so the synced nvim config
-- renders cobalt without any in-config branching. On the client, noctalia-theme.lua is
-- regenerated from the wallpaper instead. Same module interface as the generated file.

local M = {}

function M.setup()
	require("base16-colorscheme").setup({
		base00 = "#122436", -- background
		base01 = "#16304a", -- lighter background (status, line number bg)
		base02 = "#1d3f5e", -- selection background
		base03 = "#4d6b85", -- comments, invisibles
		base04 = "#8fb0c8", -- dark foreground
		base05 = "#cfe3f2", -- default foreground
		base06 = "#e6f1fb", -- light foreground
		base07 = "#ffffff", -- lightest foreground
		base08 = "#ff5c8a", -- variables, errors (neon pink — echoes the cobalt cursor)
		base09 = "#ff9e64", -- integers, constants
		base0A = "#ffd966", -- classes, search highlight
		base0B = "#8ff586", -- strings (Cobalt Neon green)
		base0C = "#5ad1ff", -- support, escape chars
		base0D = "#3aa5ff", -- functions (Cobalt Neon blue)
		base0E = "#c792ea", -- keywords
		base0F = "#d4312e", -- deprecated
	})

	local hi = function(group, opts)
		vim.api.nvim_set_hl(0, group, opts)
	end

	hi("WinSeparator", { fg = "#4d6b85", bg = "#122436" })

	hi("TelescopeNormal", { fg = "#cfe3f2", bg = "#122436" })
	hi("TelescopeBorder", { fg = "#4d6b85", bg = "#122436" })
	hi("TelescopePromptNormal", { fg = "#cfe3f2", bg = "#122436" })
	hi("TelescopePromptBorder", { fg = "#4d6b85", bg = "#122436" })
	hi("TelescopePromptPrefix", { fg = "#3aa5ff", bg = "#122436" })
	hi("TelescopePromptCounter", { fg = "#8fb0c8", bg = "#122436" })
	hi("TelescopePromptTitle", { fg = "#122436", bg = "#3aa5ff" })
	hi("TelescopePreviewTitle", { fg = "#122436", bg = "#c792ea" })
	hi("TelescopeResultsTitle", { fg = "#122436", bg = "#5ad1ff" })
	hi("TelescopeSelection", { fg = "#cfe3f2", bg = "#1d3f5e" })
	hi("TelescopeSelectionCaret", { fg = "#3aa5ff", bg = "#1d3f5e" })
	hi("TelescopeMatching", { fg = "#3aa5ff", bold = true })

	-- Bufferline links to these groups so DevIcon bgs are generated correctly
	hi("NoctaliaTabFill",     { bg = "#122436" })
	hi("NoctaliaTabInactive", { fg = "#8fb0c8", bg = "#16304a" })
	hi("NoctaliaTabVisible",  { fg = "#8fb0c8", bg = "#16304a" })
	hi("NoctaliaTabSelected", { fg = "#122436", bg = "#3aa5ff" })

	vim.notify("Cobalt: theme applied", vim.log.levels.INFO)
end

return M
