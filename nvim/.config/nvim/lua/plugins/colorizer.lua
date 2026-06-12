return {
  "NvChad/nvim-colorizer.lua",
  event = "BufReadPre",
  opts = {
    user_default_options = {
      RRGGBB = true,
      rgb_fn = true,
      hsl_fn = true,
      names = false,
      mode = "background",
      virtualtext = "●",
    },
  },
}
