# bira-status: the stock bira theme with a one-glyph git indicator.
#
# Stock bira prints the branch name and one red dot: ‹bank-2026-08-04●›.
# This copy prints neither. It prints a single git glyph, coloured by the worst
# state in the working tree:
#
#   green    clean, and level with the upstream
#   magenta  clean, but ahead of / behind / diverged from the upstream
#   blue     untracked files only
#   cyan     staged changes only
#   yellow   modified, deleted, or renamed files
#   red      merge conflicts
#
# Set BIRA_GIT_MARKS=1 in ~/.zshrc to print the plain marks after the glyph:
#
#   ? untracked   + staged   ! modified   » renamed   ✘ deleted
#   $ stashed     = conflict  ⇡ ahead     ⇣ behind    ⇕ diverged
#
# The glyph is U+E702 from a Nerd Font. kitty.conf sets
# "CaskaydiaCove Nerd Font Mono", which has it.

local return_code="%(?..%{$fg[red]%}%? ↵%{$reset_color%})"
local user_host="%B%(!.%{$fg[red]%}.%{$fg[green]%})%n@%m%{$reset_color%} "
local user_symbol='%(!.#.$)'
local current_dir="%B%{$fg[blue]%}%~ %{$reset_color%}"
local conda_prompt='$(conda_prompt_info)'

local vcs_branch='$(bira_git_indicator)$(hg_prompt_info)'
local rvm_ruby='$(ruby_prompt_info)'
local venv_prompt='$(virtualenv_prompt_info)'
if [[ "${plugins[@]}" =~ 'kube-ps1' ]]; then
    local kube_prompt='$(kube_ps1)'
else
    local kube_prompt=''
fi

ZSH_THEME_RVM_PROMPT_OPTIONS="i v g"

PROMPT="╭─${conda_prompt}${user_host}${current_dir}${rvm_ruby}${vcs_branch}${venv_prompt}${kube_prompt}
╰─%B${user_symbol}%b "
RPROMPT="%B${return_code}%b"

# git_prompt_info supplies the "am I in a repository" test only. Its output is
# never printed, so every part is empty and the value is the bare branch name.
ZSH_THEME_GIT_PROMPT_PREFIX=""
ZSH_THEME_GIT_PROMPT_SUFFIX=""
ZSH_THEME_GIT_PROMPT_DIRTY=""
ZSH_THEME_GIT_PROMPT_CLEAN=""

# git_prompt_status supplies the state. Keep these marks plain and uncoloured.
# bira_git_indicator reads them as characters, and prints them as they are when
# BIRA_GIT_MARKS is 1.
ZSH_THEME_GIT_PROMPT_UNTRACKED="?"
ZSH_THEME_GIT_PROMPT_ADDED="+"
ZSH_THEME_GIT_PROMPT_MODIFIED="!"
ZSH_THEME_GIT_PROMPT_RENAMED="»"
ZSH_THEME_GIT_PROMPT_DELETED="✘"
ZSH_THEME_GIT_PROMPT_STASHED="$"
ZSH_THEME_GIT_PROMPT_UNMERGED="="
ZSH_THEME_GIT_PROMPT_AHEAD="⇡"
ZSH_THEME_GIT_PROMPT_BEHIND="⇣"
ZSH_THEME_GIT_PROMPT_DIVERGED="⇕"

: ${BIRA_GIT_GLYPH:=$'\ue702'}
: ${BIRA_GIT_MARKS:=0}

function bira_git_indicator() {
  local info marks colour
  info="$(git_prompt_info)"
  marks="$(git_prompt_status)"

  # Outside a repository both are empty. On the first prompt in a repository
  # the async handler may not have answered yet, so marks alone also counts.
  [[ -z "$info" && -z "$marks" ]] && return

  case "$marks" in
    *=*)                colour=$fg[red] ;;
    *!*|*✘*|*»*)        colour=$fg[yellow] ;;
    *+*)                colour=$fg[cyan] ;;
    *\?*)               colour=$fg[blue] ;;
    *⇡*|*⇣*|*⇕*)        colour=$fg[magenta] ;;
    *)                  colour=$fg[green] ;;
  esac

  if [[ "$BIRA_GIT_MARKS" == 1 && -n "$marks" ]]; then
    print -n "%{$colour%}${BIRA_GIT_GLYPH} ${marks} %{$reset_color%}"
  else
    print -n "%{$colour%}${BIRA_GIT_GLYPH} %{$reset_color%}"
  fi
}

# Oh My Zsh registers the async git handlers by looking for the literal strings
# $(git_prompt_info) and $(git_prompt_status) in $PS1 (lib/git.zsh line 181).
# bira_git_indicator hides both, so register them here instead. Without these
# two lines the indicator stays empty in every repository.
if (( $+functions[_omz_register_handler] )); then
  _omz_register_handler _omz_git_prompt_info
  _omz_register_handler _omz_git_prompt_status
fi

ZSH_THEME_HG_PROMPT_PREFIX="%{$fg[yellow]%}‹"
ZSH_THEME_HG_PROMPT_SUFFIX="› %{$reset_color%}"
ZSH_THEME_HG_PROMPT_DIRTY="%{$fg[red]%}●%{$fg[yellow]%}"
ZSH_THEME_HG_PROMPT_CLEAN="%{$fg[yellow]%}"

ZSH_THEME_RUBY_PROMPT_PREFIX="%{$fg[red]%}‹"
ZSH_THEME_RUBY_PROMPT_SUFFIX="› %{$reset_color%}"

ZSH_THEME_VIRTUAL_ENV_PROMPT_PREFIX="%{$fg[green]%}‹"
ZSH_THEME_VIRTUAL_ENV_PROMPT_SUFFIX="› %{$reset_color%}"
ZSH_THEME_VIRTUALENV_PREFIX="$ZSH_THEME_VIRTUAL_ENV_PROMPT_PREFIX"
ZSH_THEME_VIRTUALENV_SUFFIX="$ZSH_THEME_VIRTUAL_ENV_PROMPT_SUFFIX"
