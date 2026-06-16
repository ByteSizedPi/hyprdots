 local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#0b1732',
    base01 = '#122654',
    base02 = '#10224c',
    base03 = '#5f6473',
    base04 = '#afb1b6',
    base05 = '#f2f2f3',
    base06 = '#f2f2f3',
    base07 = '#f2f2f3',
    base08 = '#fd4663',
    base09 = '#b357db',
    base0A = '#7157db',
    base0B = '#678de4',
    base0C = '#d096e9',
    base0D = '#93aeec',
    base0E = '#a696e9',
    base0F = '#910017',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  hi('TelescopeNormal',         { fg = '#f2f2f3',          bg = '#0b1732' })
  hi('TelescopeBorder',         { fg = '#5f6473',             bg = '#0b1732' })
  hi('TelescopePromptNormal',   { fg = '#f2f2f3',          bg = '#0b1732' })
  hi('TelescopePromptBorder',   { fg = '#5f6473',             bg = '#0b1732' })
  hi('TelescopePromptPrefix',   { fg = '#678de4',             bg = '#0b1732' })
  hi('TelescopePromptCounter',  { fg = '#afb1b6',  bg = '#0b1732' })
  hi('TelescopePromptTitle',    { fg = '#0b1732',             bg = '#678de4' })
  hi('TelescopePreviewTitle',   { fg = '#0b1732',             bg = '#7157db' })
  hi('TelescopeResultsTitle',   { fg = '#0b1732',             bg = '#b357db' })
  hi('TelescopeSelection',      { fg = '#f2f2f3',          bg = '#10224c' })
  hi('TelescopeSelectionCaret', { fg = '#678de4',             bg = '#10224c' })
  hi('TelescopeMatching',       { fg = '#678de4',             bold = true })
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
