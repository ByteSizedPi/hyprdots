return {
	{
		'nvim-lualine/lualine.nvim',
		dependencies = { 'nvim-tree/nvim-web-devicons' }, -- optional but recommended
		config = function()
			require('lualine').setup {
				options = {
					theme = 'auto', -- picks theme based on your current colorscheme
					component_separators = '',
					section_separators = '', -- clean look
					globalstatus = true,
				},
				sections = {
					lualine_a = {
						{
							'mode',
							separator = { left = '◖', right = '◗' },
							padding = { left = 0, right = 0 },
						},
					},
					lualine_b = {
						{
							'branch',
							separator = { left = '', right = '◗' },
							padding = { left = 1, right = 0 },
						},
					},
					lualine_c = { { 'filetype' }, { 'filename', path = 1 } },
					lualine_x = { 'encoding' },
					lualine_y = { '' },
					lualine_z = { '' },
				},
				inactive_sections = {
					lualine_a = {},
					lualine_b = {},
					lualine_c = { 'filename' },
					lualine_x = { '' },
					lualine_y = {},
					lualine_z = {},
				},
			}
		end,
	},
}
