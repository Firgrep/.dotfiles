#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

#=== ALIASES
alias ls='ls -la --color=auto'
alias grep='grep --color=auto'
alias cgo='~/cgo.sh'

#=== PROMPT
PROMPT_COMMAND='PS1_CMD1=$(git branch 2>/dev/null | grep '\''*'\'' | colrm 1 2); PS1="\[\e[90m\][\$(date +'%H:%M')]\[\e[36m\]\[\e[35m\]\u\[\e[0m\]:\[\e[36m\]\w"; if [ -n "$PS1_CMD1" ]; then PS1+="\[\e[0;94m\][${PS1_CMD1}]"; fi; PS1+="\[\e[0m\]\\$ "'

#=== OTHER
# bun
export BUN_INSTALL="$HOME/.bun"
export PATH=$BUN_INSTALL/bin:$PATH

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/home/filip/google-cloud-sdk/path.bash.inc' ]; then . '/home/filip/google-cloud-sdk/path.bash.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/home/filip/google-cloud-sdk/completion.bash.inc' ]; then . '/home/filip/google-cloud-sdk/completion.bash.inc'; fi
