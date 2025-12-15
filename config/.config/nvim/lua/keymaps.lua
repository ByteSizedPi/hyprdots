-- lua/keymaps.lua
-- Key mappings for Neovim

vim.g.have_nerd_font = true

-----------------------------------------------
-- GENERAL
-----------------------------------------------

-- Clear search highlights
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = 'Clear search highlights' })

-- Better command mode access (; instead of :)
vim.keymap.set('n', ';', ':', { noremap = true, desc = 'Enter command mode' })
vim.keymap.set('n', ':', ';', { noremap = true, desc = 'Repeat last f/t/F/T motion' })

-- Save file
vim.keymap.set('n', '<leader>w', '<cmd>w<CR>', { desc = 'Save file' })
vim.keymap.set('n', '<leader>W', '<cmd>wa<CR>', { desc = 'Save all files' })

-- Quit
vim.keymap.set('n', '<leader>q', '<cmd>q<CR>', { desc = 'Quit' })
vim.keymap.set('n', '<leader>Q', '<cmd>qa<CR>', { desc = 'Quit all' })

-----------------------------------------------
-- NAVIGATION
-----------------------------------------------

-- Cursor wrapping at line boundaries
vim.keymap.set('n', 'h', function()
  if vim.fn.col('.') == 1 and vim.fn.line('.') > 1 then
    return 'k$'
  else
    return 'h'
  end
end, { expr = true, desc = 'Move left (wrap to previous line end)' })

vim.keymap.set('n', 'l', function()
  if vim.fn.col('.') == vim.fn.col('$') - 1 and vim.fn.line('.') < vim.fn.line('$') then
    return 'j0'
  else
    return 'l'
  end
end, { expr = true, desc = 'Move right (wrap to next line start)' })

-- Better window navigation
vim.keymap.set('n', '<C-h>', '<C-w>h', { desc = 'Move to left window' })
vim.keymap.set('n', '<C-j>', '<C-w>j', { desc = 'Move to bottom window' })
vim.keymap.set('n', '<C-k>', '<C-w>k', { desc = 'Move to top window' })
vim.keymap.set('n', '<C-l>', '<C-w>l', { desc = 'Move to right window' })

-- Resize windows with arrows
vim.keymap.set('n', '<C-Up>', '<cmd>resize +2<CR>', { desc = 'Increase window height' })
vim.keymap.set('n', '<C-Down>', '<cmd>resize -2<CR>', { desc = 'Decrease window height' })
vim.keymap.set('n', '<C-Left>', '<cmd>vertical resize -2<CR>', { desc = 'Decrease window width' })
vim.keymap.set('n', '<C-Right>', '<cmd>vertical resize +2<CR>', { desc = 'Decrease window width' })

-- Buffer navigation
vim.keymap.set('n', '<S-h>', '<cmd>bprevious<CR>', { desc = 'Previous buffer' })
vim.keymap.set('n', '<S-l>', '<cmd>bnext<CR>', { desc = 'Next buffer' })
vim.keymap.set('n', '<leader>bd', '<cmd>bdelete<CR>', { desc = 'Delete buffer' })
vim.keymap.set('n', '<leader>bD', '<cmd>bdelete!<CR>', { desc = 'Force delete buffer' })

-- Better page navigation (keep cursor centered)
vim.keymap.set('n', '<C-d>', '<C-d>zz', { desc = 'Page down (centered)' })
vim.keymap.set('n', '<C-u>', '<C-u>zz', { desc = 'Page up (centered)' })
vim.keymap.set('n', 'n', 'nzzzv', { desc = 'Next search result (centered)' })
vim.keymap.set('n', 'N', 'Nzzzv', { desc = 'Previous search result (centered)' })

-----------------------------------------------
-- EDITING
-----------------------------------------------

-- Better indenting (stay in visual mode)
vim.keymap.set('v', '<', '<gv', { desc = 'Indent left and reselect' })
vim.keymap.set('v', '>', '>gv', { desc = 'Indent right and reselect' })

-- Move lines up/down
vim.keymap.set('n', '<A-j>', '<cmd>m .+1<CR>==', { desc = 'Move line down' })
vim.keymap.set('n', '<A-k>', '<cmd>m .-2<CR>==', { desc = 'Move line up' })
vim.keymap.set('v', '<A-j>', ":m '>+1<CR>gv=gv", { desc = 'Move selection down' })
vim.keymap.set('v', '<A-k>', ":m '<-2<CR>gv=gv", { desc = 'Move selection up' })

-- Better paste (don't yank replaced text)
vim.keymap.set('v', 'p', '"_dP', { desc = 'Paste without yanking' })

-- Delete without yanking
vim.keymap.set({ 'n', 'v' }, '<leader>d', '"_d', { desc = 'Delete without yanking' })

-- Yank to system clipboard
vim.keymap.set({ 'n', 'v' }, '<leader>y', '"+y', { desc = 'Yank to system clipboard' })
vim.keymap.set('n', '<leader>Y', '"+Y', { desc = 'Yank line to system clipboard' })

-- Paste from system clipboard
vim.keymap.set({ 'n', 'v' }, '<leader>p', '"+p', { desc = 'Paste from system clipboard' })
vim.keymap.set({ 'n', 'v' }, '<leader>P', '"+P', { desc = 'Paste before from system clipboard' })

-- Join lines but keep cursor position
vim.keymap.set('n', 'J', 'mzJ`z', { desc = 'Join lines (keep cursor position)' })

-- Select all
vim.keymap.set('n', '<C-a>', 'ggVG', { desc = 'Select all' })

-----------------------------------------------
-- QUICKFIX & LOCATION LIST
-----------------------------------------------

vim.keymap.set('n', '<leader>xq', '<cmd>copen<CR>', { desc = 'Open quickfix list' })
vim.keymap.set('n', '<leader>xQ', '<cmd>cclose<CR>', { desc = 'Close quickfix list' })
vim.keymap.set('n', '<leader>xl', '<cmd>lopen<CR>', { desc = 'Open location list' })
vim.keymap.set('n', '<leader>xL', '<cmd>lclose<CR>', { desc = 'Close location list' })
vim.keymap.set('n', '[q', '<cmd>cprev<CR>', { desc = 'Previous quickfix item' })
vim.keymap.set('n', ']q', '<cmd>cnext<CR>', { desc = 'Next quickfix item' })
vim.keymap.set('n', '[l', '<cmd>lprev<CR>', { desc = 'Previous location item' })
vim.keymap.set('n', ']l', '<cmd>lnext<CR>', { desc = 'Next location item' })

-----------------------------------------------
-- DIAGNOSTICS
-----------------------------------------------

vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Previous diagnostic' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Next diagnostic' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic error' })
vim.keymap.set('n', '<leader>xd', vim.diagnostic.setloclist, { desc = 'Open diagnostic location list' })

-----------------------------------------------
-- TERMINAL
-----------------------------------------------

-- Exit terminal mode easier
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
vim.keymap.set('t', '<C-h>', '<C-\\><C-n><C-w>h', { desc = 'Move to left window from terminal' })
vim.keymap.set('t', '<C-j>', '<C-\\><C-n><C-w>j', { desc = 'Move to bottom window from terminal' })
vim.keymap.set('t', '<C-k>', '<C-\\><C-n><C-w>k', { desc = 'Move to top window from terminal' })
vim.keymap.set('t', '<C-l>', '<C-\\><C-n><C-w>l', { desc = 'Move to right window from terminal' })

-----------------------------------------------
-- SPLITS
-----------------------------------------------

vim.keymap.set('n', '<leader>|', '<cmd>vsplit<CR>', { desc = 'Vertical split' })
vim.keymap.set('n', '<leader>-', '<cmd>split<CR>', { desc = 'Horizontal split' })

-----------------------------------------------
-- MISC
-----------------------------------------------

-- Make file executable
vim.keymap.set('n', '<leader>x', '<cmd>!chmod +x %<CR>', { silent = true, desc = 'Make file executable' })

-- Source current file
vim.keymap.set('n', '<leader><leader>s', '<cmd>source %<CR>', { desc = 'Source current file' })
