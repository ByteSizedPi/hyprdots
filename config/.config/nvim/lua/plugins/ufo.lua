return {
	{
		'kevinhwang91/nvim-ufo',
		enabled = false,
		dependencies = {
			'kevinhwang91/promise-async',
			'nvim-treesitter/nvim-treesitter',
		},
		config = function()
			require('ufo').setup {
				provider_selector = function(bufnr, filetype, buftype)
					return { 'treesitter', 'indent' }
				end,
			}

			vim.o.foldcolumn = '0'
			vim.o.foldlevel = 99
			vim.o.foldlevelstart = 99
			vim.o.foldenable = true
		end,
	},
}
