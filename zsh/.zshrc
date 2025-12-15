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
export FILE_MANAGER=pcmanfm-qt

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
# ============================================================================
# AUTO-START ZELLIJ (Kitty only)
# ============================================================================

# Only launch in kitty terminal
if [[ "$TERM" == "xterm-kitty" ]] || [[ -n "$KITTY_WINDOW_ID" ]]; then
    # Don't launch if already in zellij or not in an interactive terminal
    if [[ -z "$ZELLIJ" ]] && [[ -t 0 ]] && [[ $- == *i* ]]; then
        # Check if 'main' session exists and how many clients are attached
        if zellij list-sessions -s 2>/dev/null | grep -q "^main$"; then
            # Session exists - check if anyone is attached
            client_count=$(zellij -s main action list-clients 2>/dev/null | tail -n +2 | wc -l)

            if [[ "$client_count" -eq 0 ]]; then
                # Main session exists but no one attached - attach to it
                zellij attach main
            else
                # Main session is in use - create temporary session
                temp_session="temp-$(date +%s)-$$"
                export ZELLIJ_TEMP_SESSION="$temp_session"

                cleanup_zellij_session() {
                    if [[ -n "$ZELLIJ_TEMP_SESSION" ]] && [[ "$ZELLIJ_TEMP_SESSION" != "main" ]]; then
                        zellij kill-session "$ZELLIJ_TEMP_SESSION" 2>/dev/null
                    fi
                }
                trap cleanup_zellij_session EXIT

                zellij --session "$temp_session"
            fi
        else
            # Main session doesn't exist - create it
            zellij --session main
        fi
    fi
fi
