-- persistence.nvim names the session file from the cwd alone. It ignores where
-- the open buffers live. So `nvim /tmp/scratch/foo.py` started from ~/dotfiles
-- overwrites the ~/dotfiles session with that one unrelated buffer.
--
-- Fix: stop persistence when nvim starts on files and none of them are under
-- the cwd. A start with no file (the dashboard) leaves persistence on, so the
-- normal restore-then-work flow still saves.

---@param buf integer
---@return boolean
local function is_file_buf(buf)
  if not vim.api.nvim_buf_is_loaded(buf) or vim.bo[buf].buftype ~= "" then
    return false
  end
  if vim.tbl_contains({ "gitcommit", "gitrebase", "jj" }, vim.bo[buf].filetype) then
    return false
  end
  return vim.api.nvim_buf_get_name(buf) ~= ""
end

return {
  "folke/persistence.nvim",
  init = function()
    vim.api.nvim_create_autocmd("VimEnter", {
      group = vim.api.nvim_create_augroup("persistence_guard", { clear = true }),
      nested = true,
      callback = function()
        -- Do not load persistence just to ask. If it is not loaded, nvim
        -- started without a file and there is nothing to guard against.
        if not package.loaded["persistence"] then
          return
        end

        local cwd = vim.fn.getcwd()
        if not vim.endswith(cwd, "/") then
          cwd = cwd .. "/"
        end

        local total, under_cwd = 0, 0
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if is_file_buf(buf) then
            total = total + 1
            if vim.startswith(vim.api.nvim_buf_get_name(buf), cwd) then
              under_cwd = under_cwd + 1
            end
          end
        end

        if total > 0 and under_cwd == 0 then
          require("persistence").stop()
        end
      end,
    })
  end,
}
