 local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#242019',
    base01 = '#3c362a',
    base02 = '#363026',
    base03 = '#706a5c',
    base04 = '#b6b4af',
    base05 = '#f3f2f2',
    base06 = '#f3f2f2',
    base07 = '#f3f2f2',
    base08 = '#fd4663',
    base09 = '#89cc66',
    base0A = '#c4d65c',
    base0B = '#e4ba67',
    base0C = '#b2e996',
    base0D = '#ecce93',
    base0E = '#dce996',
    base0F = '#910017',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  hi('TelescopeNormal',         { fg = '#f3f2f2',          bg = '#242019' })
  hi('TelescopeBorder',         { fg = '#706a5c',             bg = '#242019' })
  hi('TelescopePromptNormal',   { fg = '#f3f2f2',          bg = '#242019' })
  hi('TelescopePromptBorder',   { fg = '#706a5c',             bg = '#242019' })
  hi('TelescopePromptPrefix',   { fg = '#e4ba67',             bg = '#242019' })
  hi('TelescopePromptCounter',  { fg = '#b6b4af',  bg = '#242019' })
  hi('TelescopePromptTitle',    { fg = '#242019',             bg = '#e4ba67' })
  hi('TelescopePreviewTitle',   { fg = '#242019',             bg = '#c4d65c' })
  hi('TelescopeResultsTitle',   { fg = '#242019',             bg = '#89cc66' })
  hi('TelescopeSelection',      { fg = '#f3f2f2',          bg = '#363026' })
  hi('TelescopeSelectionCaret', { fg = '#e4ba67',             bg = '#363026' })
  hi('TelescopeMatching',       { fg = '#e4ba67',             bold = true })
end

 -- Register a signal handler for SIGUSR1 (matugen updates)
 local signal = vim.uv.new_signal()
 signal:start(
   'sigusr1',
   vim.schedule_wrap(function()
     package.loaded['matugen'] = nil
     require('matugen').setup()
   end)
 )

 return M
