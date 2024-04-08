export HISTSIZE=10000
export HISTFILESIZE=10000
export HISTCONTROL=ignoredups:ignorespace

export PS1="\n\u@\h \D{%F %T} \w\n\$ "
export EDITOR=nvim

# -----
# Alias
# -----

alias apply='cd ~/setup/ && ./install.sh && cd - && . ~/.bashrc'
alias bashrc='nvim ~/setup/.bashrc && apply'
alias vimrc='nvim ~/setup/nvim/init.vim && apply'
alias install='nvim ~/setup/install.sh && apply'

alias blocal='nvim ~/.bashrc_local && . ~/.bashrc_local'

alias ls='ls -a'
alias ll='ls -al'

# -----
# Git
# -----

alias gs='git status'
alias ga='git add'
alias gaa='git add -A'
alias gc='git commit'
alias gb='git branch'
alias gba='git branch --all'
alias gl='git log'
alias gd='git diff'
alias gsw='git switch'

# -----
# Docker
# -----

alias di="docker image"
alias dc="docker container"
alias dl="docker logs"
alias dcu="docker compose up -d"
alias dcs="docker compose stop"
alias dcd="docker compose down"
alias dcl="docker compose logs"

de(){
  docker exec -it $1 bash
}

dn(){
  dc ls -a --format json | jq '.Names' | tr -d '"' | fzf
}

# -----
# fzf
# -----

# https://raw.githubusercontent.com/junegunn/fzf/master/shell/key-bindings.bash
source ~/setup/key-bindings.bash

fcd(){
  cd ~
  cd $(fd . | fzf)
}

# -----
# ASDF
# -----

. "$HOME/.asdf/asdf.sh"
. "$HOME/.asdf/completions/asdf.bash"

# -----
# ローカルの設定ファイル
# -----

if [ -f ~/.bashrc_local ]; then
  . ~/.bashrc_local
fi
