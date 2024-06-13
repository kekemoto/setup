export HISTSIZE=10000
export HISTFILESIZE=10000
export HISTCONTROL=ignoredups:ignorespace

export PS1="\n\u@\h \D{%F %T} \w\n\$ "
export EDITOR=nvim

export COLOR_RED="\e[31m"
export COLOR_GREEN="\e[32m"
export COLOR_YELLOW="\e[33m"
export COLOR_END="\e[m"

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

alias color_red="tmux select-pane -P 'bg=#350000,fg=white'"
alias color_green="tmux select-pane -P 'bg=#003500,fg=white'"
alias color_black="tmux select-pane -P 'bg=black,fg=white'"

# -----
# Git
# -----

# 補完
if [ -f ~/.config/git/git-completions.bash ]; then
  . ~/.config/git/git-completions.bash
fi

alias gs='git status'
alias gf='git fetch --all --prune'
alias ga='git add'
alias gaa='git add -A'
alias gc='git commit'
alias gb='git branch --all'
alias gd='git diff HEAD'
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
    && git add -A \
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
alias dl="docker logs -f"
alias dv="docker volume"
alias dr="docker restart -t 5"
alias dcu="docker compose up -d"
alias dcs="docker compose stop"
alias dcd="docker compose down -t 5"
alias dcl="docker compose logs -f"
# alias dcr="docker compose restart -t 5"

de(){
  docker exec -it $1 bash
}

dd(){
  echo start
  docker container stop -t 5 $1 > /dev/null
  echo container stoped $1
  docker container rm $1 > /dev/null
  echo container removed $1
  if [ ! -z $2 ]; then
    docker image rm $2 > /dev/null
    echo image removed $2
  fi
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
