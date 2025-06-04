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

## git
alias gitnew='git pull && git checkout -b'
alias gbd='git branch -d'
alias gbD='git branch -D'
alias gsync='git pull --rebase && git push'

## lazygit
alias lg='lazygit'

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
PROMPT_COMMAND='PS1_CMD1=$(git branch 2>/dev/null | grep '\''*'\'' | colrm 1 2); PS1="\[\e[90m\][\$(date +'%H:%M')]\[\e[36m\]\[\e[35m\]\u\[\e[0m\]:\[\e[36m\]\w"; if [ -n "$PS1_CMD1" ]; then PS1+="\[\e[0;94m\][${PS1_CMD1}]"; fi; PS1+="\[\e[0m\]\\$ "'

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
. "$HOME/.cargo/env"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completionexport PATH=$HOME/.local/bin:$PATH

. "$HOME/.atuin/bin/env"

[[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh
eval "$(atuin init bash)"

# pnpm
export PNPM_HOME="/home/filip/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# cockroach
export COCKROACH_INSTALL="/home/filip/cockroach"
export PATH="$COCKROACH_INSTALL:$PATH"

# nvim
export PATH="$PATH:/opt/nvim-linux64/bin"

# bin
export PATH="$HOME/.bin:$PATH"

# zoxide
eval "$(zoxide init bash)"