return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    opts.options = opts.options or {}
    opts.options.theme = "base16"
    opts.options.section_separators = { left = "", right = "" }
    opts.options.component_separators = { left = "", right = "" }
    opts.tabline = {
      lualine_b = {
        {
          "buffers",
          separator = { left = "", right = "" },
          symbols = { alternate_file = "" },
          buffers_color = {
            active   = "NoctaliaTabSelected",
            inactive = "NoctaliaTabInactive",
          },
        },
      },
    }
    return opts
  end,
}
