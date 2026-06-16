 local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#291415',
    base01 = '#452122',
    base02 = '#3e1e1f',
    base03 = '#756161',
    base04 = '#b6afaf',
    base05 = '#f3f2f2',
    base06 = '#f3f2f2',
    base07 = '#f3f2f2',
    base08 = '#d68588',
    base09 = '#86d278',
    base0A = '#deaa7d',
    base0B = '#e77479',
    base0C = '#a3e996',
    base0D = '#ec9296',
    base0E = '#e9bc96',
    base0F = '#8b1e22',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  hi('TelescopeNormal',         { fg = '#f3f2f2',          bg = '#291415' })
  hi('TelescopeBorder',         { fg = '#756161',             bg = '#291415' })
  hi('TelescopePromptNormal',   { fg = '#f3f2f2',          bg = '#291415' })
  hi('TelescopePromptBorder',   { fg = '#756161',             bg = '#291415' })
  hi('TelescopePromptPrefix',   { fg = '#e77479',             bg = '#291415' })
  hi('TelescopePromptCounter',  { fg = '#b6afaf',  bg = '#291415' })
  hi('TelescopePromptTitle',    { fg = '#291415',             bg = '#e77479' })
  hi('TelescopePreviewTitle',   { fg = '#291415',             bg = '#deaa7d' })
  hi('TelescopeResultsTitle',   { fg = '#291415',             bg = '#86d278' })
  hi('TelescopeSelection',      { fg = '#f3f2f2',          bg = '#3e1e1f' })
  hi('TelescopeSelectionCaret', { fg = '#e77479',             bg = '#3e1e1f' })
  hi('TelescopeMatching',       { fg = '#e77479',             bold = true })
end

 -- Register a signal handler for SIGUSR1 (matugen updates).
 -- Stored in a global so re-requiring the module doesn't register a second
 -- handler on top of the still-active one from the previous load.
 if not _G.__matugen_signal then
   _G.__matugen_signal = vim.uv.new_signal()
   _G.__matugen_signal:start(
     'sigusr1',
     vim.schedule_wrap(function()
       package.loaded['matugen'] = nil
       require('matugen').setup()
       -- base16 applies highlights directly without firing ColorScheme,
       -- so nudge it manually so lualine and anything else listening refreshes.
       vim.api.nvim_exec_autocmds('ColorScheme', { modeline = false })
     end)
   )
 end

 return M
