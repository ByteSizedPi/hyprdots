# ~/.zshrc

# ============================================================================
# OH-MY-ZSH CONFIGURATION
# ============================================================================

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="mytheme"            # [random] (echo $RANDOM_THEME)
zstyle ':omz:update' mode auto # update automatically without asking

# Completion settings
COMPLETION_WAITING_DOTS="true" # display red dots while waiting for completion
DISABLE_UNTRACKED_FILES_DIRTY="true"
HIST_STAMPS="dd/mm/yyyy" # man strftime for format details

# Plugins
plugins=(
    git
    # extra completion scripts
    zsh-completions
    fast-syntax-highlighting
    # live suggestions as you type
    # zsh-autocomplete
    # inline autocomplete
    zsh-autosuggestions
    fzf-tab
)

# Custom theme reload function
reload_theme() {
    source ~/.oh-my-zsh/custom/themes/mytheme.zsh-theme
    zle reset-prompt
}
trap reload_theme USR1

# Initialize Oh-My-Zsh
source $ZSH/oh-my-zsh.sh

# ============================================================================
# ENVIRONMENT VARIABLES
# ============================================================================

# Core settings
export EDITOR=nvim

# PATH configuration
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"

# ============================================================================
# KEY BINDINGS
# ============================================================================

bindkey '^H' backward-kill-word   # Ctrl+H
bindkey '^[[3;5~' kill-word       # Ctrl+Delete
bindkey '^?' backward-delete-char # Backspace
bindkey '^W' backward-kill-word   # Ctrl+W (alternate for Ctrl+Backspace)

# ============================================================================
# COMPLETION SYSTEM
# ============================================================================

fpath+=~/.zfunc
autoload -Uz compinit
compinit

# ============================================================================
# ALIASES
# ============================================================================

# Package management
alias update='sudo dnf5 update -y'
alias i='sudo dnf5 install -y '

# Enhanced command replacements
alias ls='eza --icons --group-directories-first'
alias cat='bat'
alias open='xdg-open'
export ZSHCONF='/home/jj/dotfiles/zsh'
source "$ZSHCONF/zellij-init.sh" # AUTO-START ZELLIJ

# Use kitten ssh when running in kitty (but not inside Zellij)
[[ -n "$KITTY_PID" && -z "$ZELLIJ" ]] && alias ssh="kitten ssh" || true
