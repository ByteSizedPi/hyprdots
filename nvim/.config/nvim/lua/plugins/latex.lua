return {
  {
    "lervag/vimtex",
    init = function()
      -- Viewer: full zathura integration (forward + inverse search via SyncTeX)
      vim.g.vimtex_view_method = "zathura"

      -- Compiler: latexmk with SyncTeX and continuous watch mode
      vim.g.vimtex_compiler_method = "latexmk"
      vim.g.vimtex_compiler_latexmk = {
        aux_dir = "",
        out_dir = "",
        callback = 1,
        continuous = 1,
        executable = "latexmk",
        hooks = {},
        options = {
          "-verbose",
          "-file-line-error",
          "-synctex=1",
          "-interaction=nonstopmode",
        },
      }

      -- Don't auto-open quickfix on warnings; use \le explicitly
      vim.g.vimtex_quickfix_mode = 0

      -- Enable folding for sections/environments
      vim.g.vimtex_fold_enabled = 1

      -- Conceal common LaTeX markup for cleaner reading
      vim.g.vimtex_syntax_conceal = {
        accents = 1,
        ligatures = 1,
        cites = 1,
        fancy = 1,
        spacing = 0,
        greek = 1,
        math_bounds = 1,
        math_delimiters = 1,
        math_fracs = 0,
        math_super_sub = 0,
        math_symbols = 1,
        sections = 0,
        styles = 1,
      }

      -- Ignore common non-critical lint warnings
      vim.g.vimtex_lint_ignore_warnings = {
        "Marginpar on page",
        "Float too large",
      }

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "tex",
        callback = function()
          vim.opt_local.conceallevel = 0
        end,
      })
    end,
  },
}
