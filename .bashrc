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
# Helper
# -----

__confirm(){
  echo -n "$1 (y/N) : "
  read -r yn
  case $yn in
    y|Y)
      echo '実行します'
      return 0
      ;;
    *)
      echo '中止しました'
      return 1
      ;;
  esac
}

# -----
# Git
# -----

alias gs='git status'
alias ga='git add'
alias gaa='git add -A'
alias gc='git commit'
alias gb='git branch'
alias gba='git branch --all'
alias gd='git diff'
alias gsw='git switch'

gl(){
  local num
  if [ -z $1 ]; then
    num=3
  else
    num=$1
  fi

  git log --reverse -n $num
}

grs(){
  __confirm "git reset --soft を実行しますか？" \
    && git reset --soft HEAD~
}

grh(){
  __confirm "git reset --hard を実行しますか？" \
    && git reset --hard HEAD
}

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
alias dcr="dcd && dcu"

de(){
  docker exec -it $1 bash
}

# dn(){
#   dc ls -a --format json | jq '.Names' | tr -d '"' | fzf
# }

dd(){
  dc stop $1
  dc rm $1
}

# -----
# fzf
# -----

# https://raw.githubusercontent.com/junegunn/fzf/master/shell/key-bindings.bash
source ~/setup/key-bindings.bash

fcd(){
  cd ~
  if [ -z $1 ]; then
    cd $(fd . | fzf)
  else
    cd $(fd . | fzf --query $1)
  fi
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
