# If you come from bash you might have to change your $PATH.
export PATH="$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH"

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="bira"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
    git
    sudo
    colored-man-pages
    extract
    history-substring-search
    command-not-found
    zsh-autosuggestions
    fast-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

export EDITOR="nvim"
# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
alias i="sudo dnf5 install -y"
alias ls="eza --icons"
alias la="eza -lah --icons --git"
alias tree="eza --tree --icons"
alias grep="rg --color=auto"
# alias cat="bat"

setopt COMPLETE_ALIASES
_eza_path_complete() { _files }
compdef _eza_path_complete ls la tree

# ── Hyprland instance signature: recompute, never inherit ──────────────
# The zellij server is persistent (session_serialization) and outlives the
# graphical session, so it keeps the environment frozen from whenever it first
# started. Panes inherit that, so after a logout/login
# HYPRLAND_INSTANCE_SIGNATURE names a DEAD compositor and every hyprctl call
# fails with "is Hyprland running?".
#
# The live instance is identifiable without any inherited state: its directory
# under $XDG_RUNTIME_DIR/hypr/ is the one holding hyprland.lock (dead instances
# leave their socket dir behind but no lock). So derive it rather than trust it.
#
# Only this var needs it — verified 2026-07-18: WAYLAND_DISPLAY (wayland-1) is
# recreated with the same name each session, and DBUS_SESSION_BUS_ADDRESS is the
# per-user bus, so both survive. XDG_SESSION_ID does go stale but nothing here
# reads it.
#
# Limitation: if two Hyprland instances ever run at once (Plasma on another tty
# doing its own thing is fine — this only counts *Hyprland*), both have locks
# and the newest wins, which may not be this tty's. Not currently possible here.
_hypr_refresh_signature() {
	emulate -L zsh
	local d newest
	for d in ${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr/*(/N); do
		[[ -e $d/hyprland.lock ]] || continue
		[[ -z $newest || $d/hyprland.lock -nt $newest/hyprland.lock ]] && newest=$d
	done
	[[ -n $newest ]] && export HYPRLAND_INSTANCE_SIGNATURE=${newest:t}
}

# At init (new panes) and per-prompt (panes already open across a logout, whose
# shell still holds the stale value). Costs one glob + stat; unnoticeable.
if [[ -d ${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr ]]; then
	_hypr_refresh_signature
	autoload -Uz add-zsh-hook
	add-zsh-hook precmd _hypr_refresh_signature
fi
