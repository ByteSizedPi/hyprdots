return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    opts.options = opts.options or {}
    opts.options.theme = 'base16'
    return opts
  end,
  init = function()
    vim.api.nvim_create_autocmd('ColorScheme', {
      callback = vim.schedule_wrap(function()
        local ok, ll = pcall(require, 'lualine')
        if ok then ll.setup({ options = { theme = 'base16' } }) end
      end),
    })
  end,
}
