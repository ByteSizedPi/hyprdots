-- lua/plugins/treesitter.lua

-- Languages you want parsers for
local parsers = {
	'lua',
	'vim',
	'vimdoc',
	'query',
	'bash',
	'python',
	'markdown',
	'markdown_inline',
	'json',
	'yaml',
	'toml',
	'html',
	'css',
	'javascript',
}

return {
	'nvim-treesitter/nvim-treesitter',
	branch = 'main',
	lazy = false,
	build = ':TSUpdate',
	config = function()
		local ts = require 'nvim-treesitter'

		-- Optional: override install location. Default is stdpath('data')..'/site'
		ts.setup()

		-- Install parsers (no-op if already installed)
		ts.install(parsers)

		-- Enable treesitter features per-buffer when a supported filetype loads
		vim.api.nvim_create_autocmd('FileType', {
			group = vim.api.nvim_create_augroup('johan_treesitter', { clear = true }),
			callback = function(args)
				local buf = args.buf
				local lang = vim.treesitter.language.get_lang(args.match)

				-- Bail out if there's no parser for this filetype
				if not lang or not vim.treesitter.language.add(lang) then
					return
				end

				-- Syntax highlighting
				vim.treesitter.start(buf, lang)

				-- Indentation (uses treesitter to compute indents)
				vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

				-- Folding (comment these two lines out if you don't want it)
				vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
				vim.wo.foldmethod = 'expr'
			end,
			desc = 'Enable treesitter highlighting, indent, and folding',
		})
	end,
}
