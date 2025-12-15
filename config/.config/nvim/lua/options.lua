-- lua/options.lua

-- Leader keys (should also be in init.lua before requires, but good to have here too)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Disable netrw (since you're using neo-tree)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-----------------------------------------------
-- LINE NUMBERS & DISPLAY
-----------------------------------------------
vim.opt.number = true -- Show line numbers
vim.opt.relativenumber = true -- Relative line numbers (great for motions like 5j)
vim.opt.numberwidth = 4 -- Width of number column
vim.opt.signcolumn = 'yes' -- Always show sign column (git, diagnostics, breakpoints)
vim.opt.cursorline = true -- Highlight current line
vim.opt.wrap = true -- Wrap lines
vim.opt.scrolloff = 8 -- Keep 8 lines above/below cursor when scrolling
vim.opt.sidescrolloff = 8 -- Keep 8 columns left/right of cursor

-----------------------------------------------
-- SEARCH
-----------------------------------------------
vim.opt.hlsearch = true -- Highlight search results
vim.opt.incsearch = true -- Show match as you type
vim.opt.ignorecase = true -- Ignore case when searching
vim.opt.smartcase = true -- Unless you type uppercase letters

-----------------------------------------------
-- TABS & INDENTATION
-----------------------------------------------
vim.opt.tabstop = 2 -- Number of spaces tabs count for
vim.opt.shiftwidth = 2 -- Size of indent
vim.opt.softtabstop = 2 -- Number of spaces for tab in insert mode
vim.opt.expandtab = true -- Use spaces instead of tabs
vim.opt.autoindent = true -- Copy indent from current line
vim.opt.smartindent = true -- Smart autoindenting on new line
vim.opt.shiftround = true -- Round indent to multiple of shiftwidth

-- NOTE: vim-sleuth plugin will auto-detect and override these per-file

-----------------------------------------------
-- SPLITS
-----------------------------------------------
vim.opt.splitright = true -- Vertical splits go right
vim.opt.splitbelow = true -- Horizontal splits go below
vim.opt.equalalways = true -- Resize splits equally when opening/closing

-----------------------------------------------
-- APPEARANCE & UI
-----------------------------------------------
vim.opt.termguicolors = true -- True color support (24-bit)
vim.opt.showmode = false -- Don't show mode (lualine shows it)
vim.opt.showcmd = true -- Show command in bottom bar
vim.opt.cmdheight = 1 -- Height of command line
vim.opt.laststatus = 3 -- Global statusline (single line for all splits)
vim.opt.showtabline = 1 -- Show tabline only if there are at least 2 tabs
vim.opt.conceallevel = 0 -- Don't hide characters (like `` in markdown)
vim.opt.pumheight = 10 -- Popup menu height (completion menu)
vim.opt.pumblend = 10 -- Popup menu transparency (0-100)
vim.opt.winblend = 0 -- Floating window transparency

-----------------------------------------------
-- BEHAVIOR
-----------------------------------------------
vim.opt.mouse = 'a' -- Enable mouse in all modes
vim.opt.clipboard = 'unnamedplus' -- Use system clipboard
vim.opt.undofile = true -- Persistent undo history
vim.opt.undolevels = 10000 -- More undo levels
vim.opt.swapfile = false -- No swap files (they're annoying)
vim.opt.backup = false -- No backup files
vim.opt.writebackup = false -- No backup before overwriting
vim.opt.autoread = true -- Auto-reload files changed outside vim
vim.opt.confirm = true -- Confirm before exiting unsaved buffer
vim.opt.hidden = true -- Hide abandoned buffers (don't unload them)

-----------------------------------------------
-- COMPLETION
-----------------------------------------------
vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }
vim.opt.shortmess:append 'c' -- Don't show completion messages like "match 1 of 2"
vim.opt.pumheight = 10 -- Limit completion menu height

-----------------------------------------------
-- PERFORMANCE
-----------------------------------------------
vim.opt.updatetime = 250 -- Faster CursorHold events (for diagnostics, git signs)
vim.opt.timeoutlen = 300 -- Time to wait for mapped sequence (which-key delay)
vim.opt.lazyredraw = false -- Don't redraw during macros (disabled for smoother experience)

-----------------------------------------------
-- FILE HANDLING
-----------------------------------------------
vim.opt.fileencoding = 'utf-8' -- File encoding
vim.opt.spelllang = 'en_us' -- Spell check language
vim.opt.spell = false -- Spell check off by default (toggle with ]s/[s)

-----------------------------------------------
-- FOLDING (since you have ufo plugin)
-----------------------------------------------
vim.opt.foldcolumn = '1' -- Show fold column
vim.opt.foldlevel = 99 -- Start with all folds open
vim.opt.foldlevelstart = 99 -- Start with all folds open when opening file
vim.opt.foldenable = true -- Enable folding
-- NOTE: ufo plugin will handle the actual folding method

-----------------------------------------------
-- WILDMENU (command-line completion)
-----------------------------------------------
vim.opt.wildmode = 'longest:full,full' -- Complete longest common string, then full
vim.opt.wildignore:append { '*.o', '*.obj', '.git', 'node_modules', '*.pyc' }

-----------------------------------------------
-- FORMATTING
-----------------------------------------------
vim.opt.formatoptions = vim.opt.formatoptions
	- 'a' -- Don't auto-format (this causes issues with text jumping to previous line)
	- 't' -- Don't auto-wrap text using textwidth
	+ 'c' -- Auto-wrap comments using textwidth
	+ 'q' -- Allow formatting comments with gq
	- 'o' -- Don't continue comments with o/O
	+ 'r' -- Continue comments when pressing Enter
	+ 'n' -- Recognize numbered lists
	+ 'j' -- Remove comment leader when joining lines
	- '2' -- Don't use indent of second line for rest of paragraph

-----------------------------------------------
-- LIST CHARACTERS (show whitespace)
-----------------------------------------------
vim.opt.list = true -- Show invisible characters
vim.opt.listchars = {
	tab = '→ ',
	trail = '·',
	nbsp = '␣',
	extends = '›',
	precedes = '‹',
}
vim.opt.fillchars = {
	eob = ' ', -- Empty lines at end of buffer
	fold = ' ',
	foldopen = '▾',
	foldsep = '│',
	foldclose = '▸',
}

-----------------------------------------------
-- GREP (use ripgrep if available)
-----------------------------------------------
if vim.fn.executable 'rg' == 1 then
	vim.opt.grepprg = 'rg --vimgrep --no-heading --smart-case'
	vim.opt.grepformat = '%f:%l:%c:%m'
end
