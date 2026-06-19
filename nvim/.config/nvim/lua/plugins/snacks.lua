return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      sources = {
        explorer = {
          hidden = true,
          ignored = true,
          layout = {
            hidden = { "input" },
            layout = {
              width = 35,
              min_width = 35,
              position = "right",
            },
          },
        },
      },
    },
  },
}
