local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#181825',
    base01 = '#28283e',
    base02 = '#242437',
    base03 = '#636379',
    base04 = '#afafb6',
    base05 = '#f2f2f3',
    base06 = '#f2f2f3',
    base07 = '#f2f2f3',
    base08 = '#fd4663',
    base09 = '#cc66cc',
    base0A = '#995cd6',
    base0B = '#6767e4',
    base0C = '#e996e9',
    base0D = '#9393ec',
    base0E = '#bf96e9',
    base0F = '#910017',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  hi('TelescopeNormal',         { fg = '#f2f2f3',          bg = '#181825' })
  hi('TelescopeBorder',         { fg = '#636379',             bg = '#181825' })
  hi('TelescopePromptNormal',   { fg = '#f2f2f3',          bg = '#181825' })
  hi('TelescopePromptBorder',   { fg = '#636379',             bg = '#181825' })
  hi('TelescopePromptPrefix',   { fg = '#6767e4',             bg = '#181825' })
  hi('TelescopePromptCounter',  { fg = '#afafb6',  bg = '#181825' })
  hi('TelescopePromptTitle',    { fg = '#181825',             bg = '#6767e4' })
  hi('TelescopePreviewTitle',   { fg = '#181825',             bg = '#995cd6' })
  hi('TelescopeResultsTitle',   { fg = '#181825',             bg = '#cc66cc' })
  hi('TelescopeSelection',      { fg = '#f2f2f3',          bg = '#242437' })
  hi('TelescopeSelectionCaret', { fg = '#6767e4',             bg = '#242437' })
  hi('TelescopeMatching',       { fg = '#6767e4',             bold = true })

  vim.notify('Noctalia: theme applied', vim.log.levels.INFO)
end

return M
