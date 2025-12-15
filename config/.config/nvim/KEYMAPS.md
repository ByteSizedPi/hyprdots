# Neovim Keymaps & Commands Cheatsheet

**Leader key:** `<Space>`

---

## General

| Keymap | Description |
|--------|-------------|
| `;` | Enter command mode (instead of `:`) |
| `:` | Repeat last f/t/F/T motion |
| `<Esc>` | Clear search highlights |
| `<leader>w` | Save file |
| `<leader>W` | Save all files |
| `<leader>q` | Quit |
| `<leader>Q` | Quit all |
| `<C-a>` | Select all |
| `<leader><leader>s` | Source current file |
| `<leader>x` | Make file executable |

---

## Navigation

### Window Navigation
| Keymap | Description |
|--------|-------------|
| `<C-h>` | Move to left window |
| `<C-j>` | Move to bottom window |
| `<C-k>` | Move to top window |
| `<C-l>` | Move to right window |

### Window Resize
| Keymap | Description |
|--------|-------------|
| `<C-Up>` | Increase window height |
| `<C-Down>` | Decrease window height |
| `<C-Left>` | Decrease window width |
| `<C-Right>` | Increase window width |

### Buffer Navigation
| Keymap | Description |
|--------|-------------|
| `<S-h>` | Previous buffer |
| `<S-l>` | Next buffer |
| `<leader>bd` | Delete buffer |
| `<leader>bD` | Force delete buffer |
| `<leader><leader>` | Find existing buffers (Telescope) |

### Splits
| Keymap | Description |
|--------|-------------|
| `<leader>\|` | Vertical split |
| `<leader>-` | Horizontal split |

### Page Navigation
| Keymap | Description |
|--------|-------------|
| `<C-d>` | Page down (cursor centered) |
| `<C-u>` | Page up (cursor centered) |
| `n` | Next search result (centered) |
| `N` | Previous search result (centered) |

---

## Editing

### Text Manipulation
| Keymap | Description |
|--------|-------------|
| `<` (visual) | Indent left and reselect |
| `>` (visual) | Indent right and reselect |
| `<A-j>` | Move line/selection down |
| `<A-k>` | Move line/selection up |
| `J` | Join lines (keep cursor position) |

### Clipboard
| Keymap | Description |
|--------|-------------|
| `<leader>y` | Yank to system clipboard |
| `<leader>Y` | Yank line to system clipboard |
| `<leader>p` | Paste from system clipboard |
| `<leader>P` | Paste before from system clipboard |
| `p` (visual) | Paste without yanking replaced text |
| `<leader>d` | Delete without yanking |

---

## File Navigation (Idiomatic!)

### Harpoon - Quick File Marking
| Keymap | Description |
|--------|-------------|
| `<leader>a` | Mark current file (add to Harpoon) |
| `<C-e>` | Toggle Harpoon quick menu |
| `<leader>1` | Jump to Harpoon file 1 |
| `<leader>2` | Jump to Harpoon file 2 |
| `<leader>3` | Jump to Harpoon file 3 |
| `<leader>4` | Jump to Harpoon file 4 |
| `<C-S-p>` | Previous Harpoon file |
| `<C-S-n>` | Next Harpoon file |

**Workflow:** Mark important files across different directories, then jump between them instantly!

### Oil.nvim - File Browser
| Keymap | Description |
|--------|-------------|
| `-` | Open parent directory |
| `<leader>-` | Open parent directory in floating window |

**In Oil buffer:**
| Keymap | Description |
|--------|-------------|
| `<CR>` | Open file/directory |
| `<C-s>` | Open in vertical split |
| `<C-h>` | Open in horizontal split |
| `<C-t>` | Open in new tab |
| `-` | Go to parent directory |
| `g.` | Toggle hidden files |
| `g?` | Show help |
| `<C-l>` | Refresh |

---

## Telescope - Fuzzy Finding

### Core Search
| Keymap | Description |
|--------|-------------|
| `<leader>sf` | Search files |
| `<leader>sg` | Search by grep (live grep) |
| `<leader>sw` | Search current word |
| `<leader>s.` | Search recent files |
| `<leader>sr` | Resume last search |
| `<leader>sh` | Search help tags |
| `<leader>sk` | Search keymaps |
| `<leader>ss` | Search Telescope pickers |
| `<leader>sd` | Search diagnostics |
| `<leader>sn` | Search Neovim config files |

### Additional Pickers
| Keymap | Description |
|--------|-------------|
| `<leader>sc` | Search commands |
| `<leader>sm` | Search marks |
| `<leader>sj` | Search jumplist |
| `<leader>sq` | Search quickfix list |
| `<leader>/` | Fuzzy search in current buffer |
| `<leader>s/` | Live grep in open files |

### Git Integration
| Keymap | Description |
|--------|-------------|
| `<leader>gf` | Git files |
| `<leader>gc` | Git commits |
| `<leader>gb` | Git branches |
| `<leader>gs` | Git status |

### Multi-Directory Search (Workspace-like!)
| Keymap | Description |
|--------|-------------|
| `<leader>fD` | Find files in ANY directory (prompts) |
| `<leader>fG` | Grep in ANY directory (prompts) |
| `<leader>fp` | Switch projects |

**Example Workflow:**
```
1. <leader>fD → /usr/share/applications/chromatix
2. <leader>a to mark important file
3. <leader>fD → ~/dotfiles/config/.config/chromatix
4. <leader>a to mark another file
5. <leader>1 to jump to first marked file
6. <leader>2 to jump to second marked file
```

---

## LSP (Language Server Protocol)

### Navigation
| Keymap | Description |
|--------|-------------|
| `gd` | Go to definition |
| `gr` | Go to references |
| `gI` | Go to implementation |
| `<leader>D` | Type definition |
| `<leader>ls` | Document symbols |
| `<leader>lw` | Workspace symbols |
| `<leader>lr` | LSP references (Telescope) |
| `<leader>li` | LSP implementations (Telescope) |
| `<leader>ld` | LSP definitions (Telescope) |
| `<leader>lt` | LSP type definitions (Telescope) |

### Actions
| Keymap | Description |
|--------|-------------|
| `<leader>rn` | Rename symbol |
| `<leader>ca` | Code action |
| `K` | Show hover documentation |
| `<C-k>` | Signature help (insert mode) |

---

## Diagnostics

| Keymap | Description |
|--------|-------------|
| `[d` | Previous diagnostic |
| `]d` | Next diagnostic |
| `<leader>e` | Show diagnostic error (float) |
| `<leader>xd` | Open diagnostic location list |

---

## Quickfix & Location List

| Keymap | Description |
|--------|-------------|
| `<leader>xq` | Open quickfix list |
| `<leader>xQ` | Close quickfix list |
| `<leader>xl` | Open location list |
| `<leader>xL` | Close location list |
| `[q` | Previous quickfix item |
| `]q` | Next quickfix item |
| `[l` | Previous location item |
| `]l` | Next location item |

---

## Terminal

| Keymap | Description |
|--------|-------------|
| `<Esc><Esc>` | Exit terminal mode |
| `<C-h>` (terminal) | Move to left window |
| `<C-j>` (terminal) | Move to bottom window |
| `<C-k>` (terminal) | Move to top window |
| `<C-l>` (terminal) | Move to right window |

---

## Mini.nvim Features

### Surroundings (mini.surround)
| Keymap | Description |
|--------|-------------|
| `saiw)` | Surround word with parentheses |
| `sd'` | Delete surrounding quotes |
| `sr)'` | Replace surrounding ) with ' |

### Text Objects (mini.ai)
Enhanced text objects work with:
- `i` (inside) and `a` (around)
- `()`, `[]`, `{}`, `''`, `""`, etc.
- Example: `ci"` - change inside quotes
- Example: `va)` - visually select around parentheses

### Autopairs (mini.pairs)
Automatically closes:
- `()`, `[]`, `{}`, `''`, `""`, etc.

---

## Git Signs

| Keymap | Description |
|--------|-------------|
| `]c` | Next git hunk |
| `[c` | Previous git hunk |
| `<leader>hs` | Stage hunk |
| `<leader>hr` | Reset hunk |
| `<leader>hS` | Stage buffer |
| `<leader>hu` | Undo stage hunk |
| `<leader>hR` | Reset buffer |
| `<leader>hp` | Preview hunk |
| `<leader>hb` | Blame line |
| `<leader>hd` | Diff this |
| `<leader>hD` | Diff this ~ |
| `<leader>td` | Toggle deleted |

---

## Useful Commands

### Lazy.nvim (Plugin Manager)
| Command | Description |
|---------|-------------|
| `:Lazy` | Open Lazy.nvim UI |
| `:Lazy sync` | Install/update/clean plugins |
| `:Lazy update` | Update plugins |
| `:Lazy clean` | Remove unused plugins |

### Mason (LSP/Formatter/Linter Manager)
| Command | Description |
|---------|-------------|
| `:Mason` | Open Mason UI |
| `:MasonUpdate` | Update Mason registries |
| `:MasonInstall <name>` | Install a package |
| `:MasonUninstall <name>` | Uninstall a package |

### General Vim
| Command | Description |
|---------|-------------|
| `:checkhealth` | Check Neovim health |
| `:Telescope` | Open Telescope picker selector |
| `:lua vim.print(...)` | Debug print in Lua |
| `:messages` | Show message history |
| `:Inspect` | Inspect highlight groups under cursor |
| `:InspectTree` | Show treesitter syntax tree |

---

## Workflow Tips

### Multi-Directory Project (VS Code Workspace Alternative)
1. Open any file: `nvim ~/project/file.lua`
2. Mark it with Harpoon: `<leader>a`
3. Search in different directory: `<leader>fD` → `/usr/share/myapp`
4. Mark another file: `<leader>a`
5. Jump between them: `<leader>1`, `<leader>2`
6. Save as project: Projects are auto-detected by git/patterns
7. Switch projects: `<leader>fp`

### Idiomatic File Navigation
Instead of a file tree:
1. Use `<leader>sf` to find files by name
2. Use `<leader>sg` to find files by content
3. Use `-` when you need to do file operations (Oil)
4. Mark frequently used files with Harpoon (`<leader>a`)
5. Jump to marked files with `<leader>1-4`

### Quick Edits Across Project
1. Search for text: `<leader>sg`
2. Navigate results with `<C-n>` / `<C-p>`
3. Press `<C-q>` to send to quickfix
4. Navigate with `]q` / `[q`
5. Edit each location

---

## Plugin-Specific Help

- `:h telescope.nvim` - Telescope help
- `:h harpoon` - Harpoon help
- `:h oil.nvim` - Oil help
- `:h mini.nvim` - Mini.nvim help
- `:h lspconfig` - LSP configuration help
