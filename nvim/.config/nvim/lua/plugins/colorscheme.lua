-- Both themes are installed. To switch, change the colorscheme line below.
-- Or run scripts/set-theme.sh <theme> to update both nvim and zellij at once.
return {
  {
    "folke/tokyonight.nvim",
    opts = {
      transparent = true,
      styles = { sidebars = "transparent", floats = "transparent" },
    },
  },
  {
    "Mofiqul/dracula.nvim",
    config = function()
      require("dracula").setup({ transparent_bg = true, italic_comment = true })
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight", -- change to: "dracula"
    },
  },
}
