# Omarchy compatibility layer for zsh.
#
# Omarchy's opinionated shell is bash (/usr/share/omarchy/default/bash/). This
# file brings the parts that matter into zsh. Sourced by ~/.zshrc BEFORE
# oh-my-zsh, so oh-my-zsh plugins and the personal aliases in ~/.zshrc win any
# name clash (e.g. omz's `gcm` = git checkout main vs Omarchy's git commit -m).
#
# Read from the packaged files where they are shell-neutral, so Omarchy updates
# still flow through. Never edit /usr/share/omarchy/.

: "${OMARCHY_PATH:=/usr/share/omarchy}"

# PATH + OMARCHY_PATH (POSIX sh; mise command-wrappers first, shims, ~/.local/bin)
[[ -r $OMARCHY_PATH/default/bash/env-bootstrap ]] && source $OMARCHY_PATH/default/bash/env-bootstrap

# Envs from default/bash/envs (BROWSER for gh & co., bat as man pager)
export BROWSER="${BROWSER:-omarchy-launch-browser}"
export BAT_THEME=ansi
export MANROFFOPT="-c"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# History, sized like Omarchy's bash
HISTFILE=${HISTFILE:-$HOME/.zsh_history}
HISTSIZE=32768
SAVEHIST=32768

# Tool init (zsh flavours of default/bash/init)
command -v mise   &>/dev/null && eval "$(mise activate zsh)"
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"
if command -v try &>/dev/null; then
  try() {
    unfunction try
    eval "$(SHELL=/bin/zsh command try init ~/Work/tries)"
    try "$@"
  }
fi
# fzf key bindings (Ctrl-R history, Ctrl-T files, Alt-C dirs). oh-my-zsh loads
# after this file and rebinds Ctrl-R, so bind on the first prompt instead, once.
if [[ -r /usr/share/fzf/key-bindings.zsh ]]; then
  _omarchy_fzf_keys() {
    source /usr/share/fzf/key-bindings.zsh
    add-zsh-hook -d precmd _omarchy_fzf_keys
    unfunction _omarchy_fzf_keys
  }
  autoload -Uz add-zsh-hook
  add-zsh-hook precmd _omarchy_fzf_keys
fi

# Omarchy aliases (zd/cd, lt, ff, n, cx, g...) and functions. All parse in zsh.
# fns/tmux is skipped: it indexes arrays from 0 (bash), which breaks in zsh.
source $OMARCHY_PATH/default/bash/aliases
for _f in $OMARCHY_PATH/default/bash/fns/*(N); do
  [[ ${_f:t} == tmux ]] && continue
  source $_f
done
unset _f
