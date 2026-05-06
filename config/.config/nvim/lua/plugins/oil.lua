-- Oil.nvim - Edit your filesystem like a buffer
-- https://github.com/stevearc/oil.nvim

return {
	'stevearc/oil.nvim',enabled = false,
	dependencies = { 'nvim-tree/nvim-web-devicons' },
	config = function()
		require('oil').setup {
			-- Oil will take over directory buffers (e.g. `vim .` or `:e src/`)
			default_file_explorer = true,
			columns = {
				'icon',
				-- "permissions",
				-- "size",
				-- "mtime",
			},
			-- Buffer-local options to use for oil buffers
			buf_options = {
				buflisted = false,
				bufhidden = 'hide',
			},
			-- Window-local options to use for oil buffers
			win_options = {
				wrap = false,
				signcolumn = 'no',
				cursorcolumn = false,
				foldcolumn = '0',
				spell = false,
				list = false,
				conceallevel = 3,
				concealcursor = 'nvic',
			},
			-- Send deleted files to the trash instead of permanently deleting them (:help oil-trash)
			delete_to_trash = true,
			-- Skip the confirmation popup for simple operations (:help oil.skip_confirm_for_simple_edits)
			skip_confirm_for_simple_edits = false,
			-- Selecting a new/moved/renamed file or directory will prompt you to save changes first
			-- (:help prompt_save_on_select_new_entry)
			prompt_save_on_select_new_entry = true,
			-- Keymaps in oil buffer. Can be any value that `vim.keymap.set` accepts OR a table of keymap
			-- options with a `callback` (e.g. { callback = function() ... end, desc = "", mode = "n" })
			keymaps = {
				['g?'] = 'actions.show_help',
				['<CR>'] = 'actions.select',
				['<C-s>'] = { 'actions.select', opts = { vertical = true }, desc = 'Open the entry in a vertical split' },
				['<C-h>'] = { 'actions.select', opts = { horizontal = true }, desc = 'Open the entry in a horizontal split' },
				['<C-t>'] = { 'actions.select', opts = { tab = true }, desc = 'Open the entry in new tab' },
				['<C-p>'] = 'actions.preview',
				['<C-c>'] = 'actions.close',
				['<C-l>'] = 'actions.refresh',
				['-'] = 'actions.parent',
				['_'] = 'actions.open_cwd',
				['`'] = 'actions.cd',
				['~'] = { 'actions.cd', opts = { scope = 'tab' }, desc = ':tcd to the current oil directory' },
				['gs'] = 'actions.change_sort',
				['gx'] = 'actions.open_external',
				['g.'] = 'actions.toggle_hidden',
				['g\\'] = 'actions.toggle_trash',
			},
			-- Set to false to disable all of the above keymaps
			use_default_keymaps = true,
			view_options = {
				-- Show files and directories that start with "."
				show_hidden = false,
				-- This function defines what is considered a "hidden" file
				is_hidden_file = function(name, bufnr)
					return vim.startswith(name, '.')
				end,
				-- This function defines what will never be shown, even when `show_hidden` is set
				is_always_hidden = function(name, bufnr)
					return false
				end,
				-- Sort file names in a more intuitive order for humans. Is less performant,
				-- so you may want to set to false if you work with large directories.
				natural_order = true,
				sort = {
					-- sort order can be "asc" or "desc"
					-- see :help oil-columns to see which columns are sortable
					{ 'type', 'asc' },
					{ 'name', 'asc' },
				},
			},
		}

		-- Open parent directory in current window
		vim.keymap.set('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent directory' })

		-- Open parent directory in floating window
		vim.keymap.set('n', '<leader>-', require('oil').toggle_float, { desc = 'Open parent directory in float' })
	end,
}
