eval "$(/opt/homebrew/bin/brew shellenv)"

# mise
eval "$(mise activate zsh)"

# go
export GOROOT=$HOME/.local/share/mise/installs/go/latest/go

# ghq
alias gf='(){cd $(fd -t d -d 2 . ~/ghq/github.com | grep -E "ghq/github.com/[^/]+/.+" | sort | fzf -1 --preview "find {} | grep README | xargs cat" --query="$1")}'

# code by fzf
alias codef='(){code $(fd -t d -d 2 . ~/ghq/github.com | grep -E "ghq/github.com/[^/]+/.+" | sort | fzf -1 --preview "find {} | grep README | xargs cat" --query="$1")}'

# fzfセッティング
export FZF_DEFAULT_OPTS='--layout=reverse --inline-info'

# yabaiのリスタート
alias yabair='yabai --restart-service'
