eval "$(/opt/homebrew/bin/brew shellenv)"

# mise
eval "$(mise activate zsh)"

# go
export GOROOT=$HOME/.local/share/mise/installs/go/latest/go

# ghq
alias gf='cd $(find ~/src/github.com -depth 2 | fzf)'

# code by fzf
alias codef='code $(find ~/src/github.com -depth 2 | fzf)'
