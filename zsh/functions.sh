# ============================================================================
# SHELL FUNCTIONS
# ============================================================================

# Fuzzy package manager — fpkg [initial search term]
#   ENTER     = install selected
#   ctrl-x    = remove selected
#   TAB       = multi-select
#   ctrl-/    = toggle preview pane
#   Green ✓   = already installed
fpkg() {
  local tmpinstalled
  tmpinstalled=$(mktemp)
  dnf repoquery --installed --qf '%{name}\n' 2>/dev/null | sort -u > "$tmpinstalled"

  local result
  result=$(dnf repoquery --available --qf '%{name}\n' 2>/dev/null | sort -u | \
    awk -v inst="$tmpinstalled" '
      BEGIN { while ((getline line < inst) > 0) installed[line] = 1 }
      {
        if ($0 in installed)
          printf "\033[32m✓\033[0m %s\n", $0
        else
          printf "  %s\n", $0
      }
    ' | fzf \
      --ansi \
      --layout=reverse \
      --multi \
      --query="${*}" \
      --prompt="Packages › " \
      --header="ENTER=install   ctrl-x=remove   TAB=multi-select   ctrl-/=preview" \
      --preview='dnf info {2} 2>/dev/null' \
      --preview-window='right:50%:wrap' \
      --bind='ctrl-/:toggle-preview' \
      --expect='ctrl-x')

  rm -f "$tmpinstalled"
  [[ -z "$result" ]] && return

  local key packages
  key=$(head -1 <<< "$result")
  packages=$(tail -n +2 <<< "$result" | awk '{print $NF}')
  [[ -z "$packages" ]] && return

  if [[ "$key" == "ctrl-x" ]]; then
    sudo dnf remove $packages
  else
    sudo dnf install $packages
  fi
}
