#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

## hstr
if [ -f /usr/bin/hstr ]; then
    alias hh='hstr' # hh to be used instead of hstr
    # Bind Ctrl-r to hstr
    bind '"\C-r": "\C-a hstr -- \C-j"'
    export HSTR_CONFIG=hicolor
fi

#=== ALIASES
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ..2='cd ../..'
alias ..3='cd ../../..'
alias c='clear'
alias chmod="chmod -c"
alias cp='cp -iv'
alias df="df -h"
alias grep='grep --color=auto'
alias ls='ls -la --color=auto'
alias mkdir='mkdir -pv'
alias mv='mv -iv'
alias stow='stow -v'
alias rm='rm -v'
alias br='bun run'
alias backup="~/.dotfiles/backup.sh"
alias here="xdg-open . &"
alias k9s='~/dev/tools/k9s/execs/k9s'
alias claude='claude --permission-mode auto'
alias wm='workmux'
alias k=kubectl
alias ktest="kubectl --context=happi-aks-test"
alias kprod="kubectl --context=happi-aks-prod"
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

alias op-fable="opencode -m github-copilot/claude-fable-5"
alias op-opus="opencode -m github-copilot/claude-opus-5"
alias op-sonnet="opencode -m github-copilot/claude-sonnet-5"
alias op-terra="opencode -m github-copilot/gpt-5.6-terra"
alias op-sol="opencode -m github-copilot/gpt-5.6-sol"
alias op-luna="opencode -m github-copilot/gpt-5.6-luna"
alias op-flash="opencode -m github-copilot/gemini-3.8-flash"

e() { code "${1:-.}"; }

v() {
  if [ $# -eq 0 ]; then
    nvim .
  else
    nvim "$@"
  fi
}

## git
alias gitnew='git pull && git checkout -b'
alias gbd='git branch -d'
alias gbD='git branch -D'
alias gsync='git pull --rebase && git push'

## lazygit
alias lg='lazygit'

# pnpm
alias pn='pnpm'

## scripts
alias cgo='~/cgo.sh'
alias sy='~/sy.sh'
alias fn='~/fn.sh'
alias pipeline='~/pipeline.sh'

## get top process eating memory
alias mem5='ps auxf | sort -nr -k 4 | head -5'
alias mem10='ps auxf | sort -nr -k 4 | head -10'

## get top process eating cpu ##
alias cpu5='ps auxf | sort -nr -k 3 | head -5'
alias cpu10='ps auxf | sort -nr -k 3 | head -10'

## List largest directories (aka "ducks")
alias dir5='du -cksh * | sort -hr | head -n 5'
alias dir10='du -cksh * | sort -hr | head -n 10'

#=== PROMPT
# always know the kubectl context before writing changes to prod unknowingly
__kube_context_prompt() {
    local context reset='\[\e[0m\]'
    local matrix='\[\e[92m\]'     # neon matrix green
    local prod_hl='\[\e[97;41m\]' # white on red, for "prod" only

    context=$(kubectl config current-context 2>/dev/null) || return

    local display="$context"
    if [[ "$context" == *prod* ]]; then
        display="${context//prod/${prod_hl}prod${reset}${matrix}}"
    fi

    printf '%s[⎈ %s]%s' "$matrix" "$display" "$reset"
}

PROMPT_COMMAND='PS1_CMD1=$(git branch 2>/dev/null | grep '\''*'\'' | colrm 1 2); PS1="\[\e[90m\][\$(date +'\''%H:%M'\'')]\[\e[36m\]\[\e[35m\]\u\[\e[0m\]:\[\e[36m\]\w"; if [ -n "$PS1_CMD1" ]; then PS1+="\[\e[0;94m\][${PS1_CMD1}]"; fi; PS1_CMD2=$(__kube_context_prompt); if [ -n "$PS1_CMD2" ]; then PS1+="${PS1_CMD2}"; fi; PS1+="\[\e[0m\]\\$ "'

#=== OTHER
# bun
export BUN_INSTALL="$HOME/.bun"
export PATH=$BUN_INSTALL/bin:$PATH

# stripe
export PATH="$HOME/src/stripe:$PATH"

# other local bin
export PATH="$HOME/.local/bin:$PATH"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/home/filip/google-cloud-sdk/path.bash.inc' ]; then . '/home/filip/google-cloud-sdk/path.bash.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/home/filip/google-cloud-sdk/completion.bash.inc' ]; then . '/home/filip/google-cloud-sdk/completion.bash.inc'; fi

# go
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

# cargo
. "$HOME/.cargo/env"
export PATH="$PATH:$HOME/.cargo/bin"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

. "$HOME/.atuin/bin/env"

[[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh
eval "$(atuin init bash)"

eval "$(fzf --bash)"

complete -C /usr/bin/terraform terraform

# opencode
export PATH=/home/filip/.opencode/bin:$PATH

# pnpm
export PNPM_HOME="/home/filip/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
# pnpm end

# cockroach
export COCKROACH_INSTALL="/home/filip/cockroach"
export PATH="$COCKROACH_INSTALL:$PATH"

# nvim
export PATH="$PATH:/opt/nvim-linux64/bin"

# bin
export PATH="$HOME/.bin:$PATH"

# kotlin
export PATH="$PATH:$HOME/kotlinc/bin"

# zoxide
eval "$(zoxide init bash)"

# Shortcut to run a program in a specific sway workspace.
#   ww 2 code .          -> workspace 2 (wherever it lives), launch
#   ww up 2 code .       -> workspace 2, moved to the output above, launch
#   ww up code .         -> fresh workspace on the output above, launch
#   ww code .            -> fresh workspace on the current output, launch
ww() {
    local dir="" ws
    case "$1" in
        up|down|left|right) dir="$1"; shift ;;
    esac
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        ws="$1"
        shift
    else
        ws=$(ws_free)
    fi
    swaymsg workspace "$ws"
    [ -n "$dir" ] && swaymsg move workspace to output "$dir"
    if [ $# -gt 0 ]; then
        "$@"
    fi
}

# Lowest unused numbered sway workspace, e.g. ww up "$(ws_free)" code .
ws_free() {
    local used n=1
    used=$(swaymsg -t get_workspaces | jq '[.[].num]')
    while echo "$used" | jq -e "index($n)" >/dev/null; do n=$((n + 1)); done
    echo "$n"
}
