 local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#000000',
    base01 = '#0d0d0d',
    base02 = '#191919',
    base03 = '#606060',
    base04 = '#5d5d5d',
    base05 = '#828282',
    base06 = '#828282',
    base07 = '#828282',
    base08 = '#dddddd',
    base09 = '#cccccc',
    base0A = '#a7a7a7',
    base0B = '#aaaaaa',
    base0C = '#e99696',
    base0D = '#e99696',
    base0E = '#e99696',
    base0F = '#967171',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  hi('TelescopeNormal',         { fg = '#828282',          bg = '#000000' })
  hi('TelescopeBorder',         { fg = '#606060',             bg = '#000000' })
  hi('TelescopePromptNormal',   { fg = '#828282',          bg = '#000000' })
  hi('TelescopePromptBorder',   { fg = '#606060',             bg = '#000000' })
  hi('TelescopePromptPrefix',   { fg = '#aaaaaa',             bg = '#000000' })
  hi('TelescopePromptCounter',  { fg = '#5d5d5d',  bg = '#000000' })
  hi('TelescopePromptTitle',    { fg = '#000000',             bg = '#aaaaaa' })
  hi('TelescopePreviewTitle',   { fg = '#000000',             bg = '#a7a7a7' })
  hi('TelescopeResultsTitle',   { fg = '#000000',             bg = '#cccccc' })
  hi('TelescopeSelection',      { fg = '#828282',          bg = '#191919' })
  hi('TelescopeSelectionCaret', { fg = '#aaaaaa',             bg = '#191919' })
  hi('TelescopeMatching',       { fg = '#aaaaaa',             bold = true })
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
