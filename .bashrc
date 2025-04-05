export HISTSIZE=10000
export HISTFILESIZE=10000
export HISTCONTROL=ignoredups:ignorespace

export PS1="\n\u@\h \D{%F %T} \w\n\$ "
export EDITOR=nvim

# export COLOR_RED="\e[31m"
# export COLOR_GREEN="\e[32m"
# export COLOR_YELLOW="\e[33m"
# export COLOR_END="\e[m"

# -----
# Alias
# -----

alias apply='cd ~/setup/ && ./install.sh && cd - && . ~/.bashrc'
alias bashrc='nvim ~/setup/.bashrc && apply'
alias blocal='nvim ~/.bashrc_local && . ~/.bashrc_local'
alias vimrc='nvim ~/setup/nvim/init.vim && apply'
alias tmuxrc='nvim ~/setup/.tmux.conf && apply'
alias install='nvim ~/setup/install.sh && apply'

alias ls='ls -a'
alias ll='ls -al'
alias setup='cd ~/setup'

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

map(){
    while read LINE
    do
        "$@" $LINE
    done
}

is_wsl(){
  command -v powershell.exe >/dev/null
}

append(){
  cat -
  echo $1
}

alias color_red="tmux select-pane -P 'bg=#350000,fg=white'"
alias color_green="tmux select-pane -P 'bg=#003500,fg=white'"
alias color_black="tmux select-pane -P 'bg=black,fg=white'"

# -----
# Command
# -----

# 標準出力の内容をクリップボードに
yank(){
  if is_wsl; then
    iconv -t cp932 | clip.exe
  else
    echo "非対応です" >&2
  fi
}

# rg で検索し、置換する
rgsed(){
  read -p "検索クエリを入力してください: " query
  read -p "置換する文字列を入力してください: " replace
  mapfile -t results < <(rg --vimgrep "$query")
  for line in "${results[@]}"; do
    _rgsed $line
  done
}

_rgsed(){
  line="$@"

  # 検索結果のパース
  file=$(echo "$line" | awk -F ':' '{print $1}')
  lineno=$(echo "$line" | awk -F ':' '{print $2}')
  text=$(echo "$line" | awk -F ':' '{print $4}')

  # 結果の表示
  echo "======"
  echo "$file : $lineno"
  echo "$text"

  # 操作の選択
  echo "------"
  echo "r: 置換"
  echo "n: 次へ"
  echo "e: エディターで開く"
  read -p "入力: " action

  case $action in
    r)
      sed -i "${lineno}s|$query|$replace|" "$file"
      ;;
    n)
      ;;
    e)
      nvim +$lineno "$file"
      _rgsed $line
      ;;
    *)
      _rgsed $line
      ;;
  esac
}

llm(){
  #local message=$(jq -Rs .)
  local message=$(cat -)
  local model=${1:-claude-3-5-haiku-latest}
  local tmpfile=$(mktemp)

  jq -n \
    --arg model "$model" \
    --arg content "$message" \
    '{
      model: $model,
      max_tokens: 1024,
      messages: [{role: "user", content: $content}]
    }' | curl -sS --fail-with-body -o "$tmpfile" https://api.anthropic.com/v1/messages \
       --header "x-api-key: $ANTHROPIC_API_KEY" \
       --header "anthropic-version: 2023-06-01" \
       --header "content-type: application/json" \
       --data-binary @-

  if [ $? -ne 0 ]; then
    cat "$tmpfile"
  else
    jq -r '.content[0].text' "$tmpfile"
  fi

  rm -f "$tmpfile"
}


# -----
# Sound
# -----

beep(){
  local result=$?
  if is_wsl; then
    # WSL の場合
    if [ $result -eq 0 ]; then
      beep_success
      echo OK
    else
      beep_fail
      echo ERROR
    fi
  else
    # Linux の場合
    echo -e '\a'
  fi
}

beep_beep(){
  local lag="[console]::beep(37,2000);" # ラグ対策に無音に近い音を2秒
  local do="[console]::beep(440,500);" # ド
  local re="[console]::beep(494,500);" # レ
  local mi="[console]::beep(554,500);" # ミ
  powershell.exe -Command $lag$mi$re$do
}

beep_good(){
  local lag="[console]::beep(37,2000);" # ラグ対策に無音に近い音を2秒
  local do="[console]::beep(440,100);" # ド
  local re="[console]::beep(494,100);" # レ
  local res="[console]::beep(523,100);" # レ#
  local mi="[console]::beep(554,100);" # ミ
  local fa="[console]::beep(587,100);" # ファ
  local fas="[console]::beep(622,100);" # ファ#
  local so="[console]::beep(659,100);" # ソ
  local sos="[console]::beep(699,100);" # ソ#
  local ra="[console]::beep(740,100);" # ラ
  local si="[console]::beep(831,100);" # シ
  powershell.exe -Command $lag$fas$fa$re$sos$so$res$so$si
}

beep_bad(){
  local lag="[console]::beep(37,2000);" # ラグ対策に無音に近い音を2秒
  local do="[console]::beep(440,100);" # ド
  local re="[console]::beep(494,100);" # レ
  local mi="[console]::beep(554,100);" # ミ
  local fa="[console]::beep(587,100);" # ファ
  local fa="[console]::beep(622,100);" # ファ#
  local so="[console]::beep(659,100);" # ソ
  local ra="[console]::beep(740,100);" # ラ
  local si="[console]::beep(831,100);" # シ
  powershell.exe -Command $lag$si$fa$fa$fa$mi$re$do
}

# simple sound
beep_success(){
  local lag="[console]::beep(37,2000);" # ラグ対策に無音に近い音を2秒
  local fa="[console]::beep(587,100);" # ファ
  local si="[console]::beep(831,100);" # シ
  powershell.exe -Command $lag$fa$si$si
}

# simple sound
beep_fail(){
  local lag="[console]::beep(37,2000);" # ラグ対策に無音に近い音を2秒
  local do="[console]::beep(440,100);" # ド
  local fa="[console]::beep(587,100);" # ファ
  powershell.exe -Command $lag$fa$do$do
}

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
alias gcb='git commit -m backup --no-verify'
alias gb='git branch'
alias gd='git diff @'
alias gd1='git diff @~ @'

gl(){
  local num
  if [ -z $1 ]; then
    num=3
  else
    num=$1
  fi

  git log --reverse -n $num
}

gan(){
  # git ls-files --others --exclude-standard -z | xargs -0 git add -N
  git add -AN
}

gap(){
  gan
  git add -p "$@"
}

gcm(){
  local msg=$(make_git_commit_message)
  __confirm "「$msg」でコミットしますか？" || return
  git commit -m "$msg"
}

make_git_commit_message(){
  git diff --staged | append "上記の差分の内容から git commit のメッセージを考えてください。一行目に概要を短く書き、詳細は三行目以降に書いてください。それを日本語でコミットメッセージだけを直接出力してください" | llm
}

grs(){
  __confirm "git reset --soft を実行しますか？" \
    && git reset --soft HEAD~
}

grh(){
  __confirm "git reset --hard を実行しますか？" \
    && git add -A \
    && git reset --hard HEAD
}

gpull(){
  gf
  git pull
}

g_rebase(){
  local now=$(git branch --show-current)
  git switch main && \
  gpull && \
  git switch $now && \
  git rebase main
}

g_save(){
  git stash save -u
}

g_pop(){
  git stash pop
}

# -----
# Docker
# -----

alias di="docker image"
alias dc="docker container"
alias dl="docker logs -f"
alias dv="docker volume"
alias dr="docker restart -t 5"
alias dcu="docker compose up -d && dcl"
alias dcs="docker compose stop"
alias dcd="docker compose down -t 5"
alias dcl="docker compose logs -f"
# alias dcr="docker compose restart -t 5"

de(){
  if [ -z $2 ]; then
    docker exec -it $1 bash
  else
    docker exec -it $1 $2
  fi
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

# -----
# ローカルの設定ファイル
# -----

if [ -f ~/.bashrc_local ]; then
  . ~/.bashrc_local
fi
