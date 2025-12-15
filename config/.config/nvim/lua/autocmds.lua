-- lua/autocmds.lua
-- Autocommands for Neovim

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-----------------------------------------------
-- HIGHLIGHT ON YANK
-----------------------------------------------

-- Briefly highlight yanked text
autocmd('TextYankPost', {
	desc = 'Highlight when yanking (copying) text',
	group = augroup('highlight-yank', { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})

-----------------------------------------------
-- RESTORE CURSOR POSITION
-----------------------------------------------

-- Return to last edit position when opening files
autocmd('BufReadPost', {
	desc = 'Restore cursor position',
	group = augroup('restore-cursor', { clear = true }),
	callback = function()
		local mark = vim.api.nvim_buf_get_mark(0, '"')
		local lcount = vim.api.nvim_buf_line_count(0)
		if mark[1] > 0 and mark[1] <= lcount then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

-----------------------------------------------
-- AUTO-CREATE DIRECTORIES
-----------------------------------------------

-- Automatically create parent directories when saving a file
autocmd('BufWritePre', {
	desc = 'Auto-create parent directories on save',
	group = augroup('auto-create-dir', { clear = true }),
	callback = function(event)
		if event.match:match '^%w%w+://' then
			return
		end
		local file = vim.uv.fs_realpath(event.match) or event.match
		vim.fn.mkdir(vim.fn.fnamemodify(file, ':p:h'), 'p')
	end,
})

-----------------------------------------------
-- RESIZE SPLITS ON WINDOW RESIZE
-----------------------------------------------

-- Auto-resize splits when window is resized
autocmd('VimResized', {
	desc = 'Resize splits if window got resized',
	group = augroup('resize-splits', { clear = true }),
	callback = function()
		local current_tab = vim.fn.tabpagenr()
		vim.cmd 'tabdo wincmd ='
		vim.cmd('tabnext ' .. current_tab)
	end,
})

-----------------------------------------------
-- CLOSE CERTAIN BUFFERS WITH 'q'
-----------------------------------------------

-- Close certain filetypes with 'q'
autocmd('FileType', {
	desc = 'Close certain filetypes with q',
	group = augroup('close-with-q', { clear = true }),
	pattern = {
		'help',
		'qf',
		'query',
		'man',
		'lspinfo',
		'checkhealth',
		'startuptime',
		'notify',
	},
	callback = function(event)
		vim.bo[event.buf].buflisted = false
		vim.keymap.set('n', 'q', '<cmd>close<CR>', { buffer = event.buf, silent = true, desc = 'Close buffer' })
	end,
})

-----------------------------------------------
-- REMOVE TRAILING WHITESPACE
-----------------------------------------------

-- Remove trailing whitespace on save (optional)
-- Uncomment if you want this behavior
-- autocmd('BufWritePre', {
-- 	desc = 'Remove trailing whitespace on save',
-- 	group = augroup('trim-whitespace', { clear = true }),
-- 	pattern = '*',
-- 	callback = function()
-- 		local save_cursor = vim.fn.getpos '.'
-- 		vim.cmd [[%s/\s\+$//e]]
-- 		vim.fn.setpos('.', save_cursor)
-- 	end,
-- })

-----------------------------------------------
-- BETTER TERMINAL SETTINGS
-----------------------------------------------

-- Terminal settings
autocmd('TermOpen', {
	desc = 'Terminal settings',
	group = augroup('terminal-settings', { clear = true }),
	callback = function()
		vim.opt_local.number = false
		vim.opt_local.relativenumber = false
		vim.opt_local.signcolumn = 'no'
		-- Auto enter insert mode
		vim.cmd 'startinsert'
	end,
})

-----------------------------------------------
-- FILE TYPE SPECIFIC SETTINGS
-----------------------------------------------

-- Set wrap and spell for text files
autocmd('FileType', {
	desc = 'Wrap and spell for text files',
	group = augroup('wrap-spell', { clear = true }),
	pattern = { 'gitcommit', 'markdown', 'text' },
	callback = function()
		vim.opt_local.wrap = true
		vim.opt_local.spell = true
	end,
})

-- Conceallevel for json files
autocmd('FileType', {
	desc = 'Fix conceallevel for json files',
	group = augroup('json-conceal', { clear = true }),
	pattern = { 'json', 'jsonc', 'json5' },
	callback = function()
		vim.opt_local.conceallevel = 0
	end,
})

-----------------------------------------------
-- CHECK IF FILE CHANGED OUTSIDE OF VIM
-----------------------------------------------

-- Check if we need to reload the file when it changed outside of vim
autocmd({ 'FocusGained', 'TermClose', 'TermLeave' }, {
	desc = 'Check if file changed outside of vim',
	group = augroup('checktime', { clear = true }),
	callback = function()
		if vim.o.buftype ~= 'nofile' then
			vim.cmd 'checktime'
		end
	end,
})

-----------------------------------------------
-- GO TO LAST LOC WHEN OPENING A BUFFER
-----------------------------------------------

-- Don't restore cursor position for git commits
autocmd('FileType', {
	desc = "Don't restore cursor for git commits",
	group = augroup('no-restore-gitcommit', { clear = true }),
	pattern = { 'gitcommit', 'gitrebase' },
	callback = function()
		vim.cmd 'normal! gg'
	end,
})
