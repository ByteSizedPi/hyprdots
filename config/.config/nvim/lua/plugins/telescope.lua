return {
	{ -- Fuzzy Finder (files, lsp, etc)
		'nvim-telescope/telescope.nvim',
		event = 'VimEnter',
		dependencies = {
			'nvim-lua/plenary.nvim',
			{ -- If encountering errors, see telescope-fzf-native README for installation instructions
				'nvim-telescope/telescope-fzf-native.nvim',

				-- `build` is used to run some command when the plugin is installed/updated.
				-- This is only run then, not every time Neovim starts up.
				build = 'make',

				-- `cond` is a condition used to determine whether this plugin should be
				-- installed and loaded.
				cond = function()
					return vim.fn.executable 'make' == 1
				end,
			},
			{ 'nvim-telescope/telescope-ui-select.nvim' },

			-- Useful for getting pretty icons, but requires a Nerd Font.
			{ 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
		},
		config = function()
			-- Telescope is a fuzzy finder that comes with a lot of different things that
			-- it can fuzzy find! It's more than just a "file finder", it can search
			-- many different aspects of Neovim, your workspace, LSP, and more!
			--
			-- The easiest way to use Telescope, is to start by doing something like:
			--  :Telescope help_tags
			--
			-- After running this command, a window will open up and you're able to
			-- type in the prompt window. You'll see a list of `help_tags` options and
			-- a corresponding preview of the help.
			--
			-- Two important keymaps to use while in Telescope are:
			--  - Insert mode: <c-/>
			--  - Normal mode: ?
			--
			-- This opens a window that shows you all of the keymaps for the current
			-- Telescope picker. This is really useful to discover what Telescope can
			-- do as well as how to actually do it!

			-- [[ Configure Telescope ]]
			-- See `:help telescope` and `:help telescope.setup()`
			require('telescope').setup {
				-- You can put your default mappings / updates / etc. in here
				--  All the info you're looking for is in `:help telescope.setup()`
				defaults = {
					mappings = {
						i = {
							['<C-u>'] = false,
							['<C-d>'] = false,
						},
					},
					-- Better layout
					layout_strategy = 'horizontal',
					layout_config = {
						horizontal = {
							prompt_position = 'top',
							preview_width = 0.55,
							results_width = 0.8,
						},
						vertical = {
							mirror = false,
						},
						width = 0.87,
						height = 0.80,
						preview_cutoff = 120,
					},
					sorting_strategy = 'ascending',
					winblend = 0,
					-- Show hidden files but not .git
					file_ignore_patterns = { '.git/' },
					vimgrep_arguments = {
						'rg',
						'--color=never',
						'--no-heading',
						'--with-filename',
						'--line-number',
						'--column',
						'--smart-case',
						'--hidden', -- Show hidden files
						'--glob=!.git/', -- But exclude .git directory
					},
				},
				pickers = {
					find_files = {
						-- Show hidden files
						hidden = true,
					},
				},
				extensions = {
					['ui-select'] = {
						require('telescope.themes').get_dropdown(),
					},
				},
			}

			-- Enable Telescope extensions if they are installed
			pcall(require('telescope').load_extension, 'fzf')
			pcall(require('telescope').load_extension, 'ui-select')

			-- See `:help telescope.builtin`
			local builtin = require 'telescope.builtin'

			-- Core search keymaps
			vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
			vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
			vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
			vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
			vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
			vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
			vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
			vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
			vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
			vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

			-- Additional useful pickers
			vim.keymap.set('n', '<leader>sc', builtin.commands, { desc = '[S]earch [C]ommands' })
			vim.keymap.set('n', '<leader>sm', builtin.marks, { desc = '[S]earch [M]arks' })
			vim.keymap.set('n', '<leader>sj', builtin.jumplist, { desc = '[S]earch [J]umplist' })
			vim.keymap.set('n', '<leader>sq', builtin.quickfix, { desc = '[S]earch [Q]uickfix' })

			-- Git pickers
			vim.keymap.set('n', '<leader>gf', builtin.git_files, { desc = '[G]it [F]iles' })
			vim.keymap.set('n', '<leader>gc', builtin.git_commits, { desc = '[G]it [C]ommits' })
			vim.keymap.set('n', '<leader>gb', builtin.git_branches, { desc = '[G]it [B]ranches' })
			vim.keymap.set('n', '<leader>gs', builtin.git_status, { desc = '[G]it [S]tatus' })

			-- Slightly advanced example of overriding default behavior and theme
			vim.keymap.set('n', '<leader>/', function()
				-- You can pass additional configuration to Telescope to change the theme, layout, etc.
				builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
					winblend = 10,
					previewer = true,
				})
			end, { desc = '[/] Fuzzily search in current buffer' })

			-- Search in open files
			vim.keymap.set('n', '<leader>s/', function()
				builtin.live_grep {
					grep_open_files = true,
					prompt_title = 'Live Grep in Open Files',
				}
			end, { desc = '[S]earch [/] in Open Files' })

			-- Shortcut for searching your Neovim configuration files
			vim.keymap.set('n', '<leader>sn', function()
				builtin.find_files { cwd = vim.fn.stdpath 'config' }
			end, { desc = '[S]earch [N]eovim files' })

			-- Custom function to search in multiple directories (VS Code workspace-like)
			-- This allows you to specify multiple directories to search in
			vim.keymap.set('n', '<leader>fD', function()
				-- Example: Prompt for directory to search
				vim.ui.input({ prompt = 'Search directory: ', default = vim.fn.getcwd(), completion = 'dir' }, function(input)
					if input then
						builtin.find_files { cwd = input, hidden = true }
					end
				end)
			end, { desc = '[F]ind in [D]irectory' })

			vim.keymap.set('n', '<leader>fG', function()
				-- Example: Prompt for directory to grep
				vim.ui.input({ prompt = 'Grep directory: ', default = vim.fn.getcwd(), completion = 'dir' }, function(input)
					if input then
						builtin.live_grep { cwd = input }
					end
				end)
			end, { desc = '[F]ind by [G]rep in directory' })

			-- LSP pickers
			vim.keymap.set('n', '<leader>ls', builtin.lsp_document_symbols, { desc = '[L]SP Document [S]ymbols' })
			vim.keymap.set('n', '<leader>lw', builtin.lsp_workspace_symbols, { desc = '[L]SP [W]orkspace Symbols' })
			vim.keymap.set('n', '<leader>lr', builtin.lsp_references, { desc = '[L]SP [R]eferences' })
			vim.keymap.set('n', '<leader>li', builtin.lsp_implementations, { desc = '[L]SP [I]mplementations' })
			vim.keymap.set('n', '<leader>ld', builtin.lsp_definitions, { desc = '[L]SP [D]efinitions' })
			vim.keymap.set('n', '<leader>lt', builtin.lsp_type_definitions, { desc = '[L]SP [T]ype Definitions' })
		end,
	},
}
