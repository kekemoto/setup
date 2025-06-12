export HISTSIZE=10000
export HISTFILESIZE=10000
export HISTCONTROL=ignoredups:ignorespace

export COLOR_RED="\e[31m"
export COLOR_GREEN="\e[32m"
export COLOR_YELLOW="\e[33m"
export COLOR_END="\e[m"

export EDITOR=nvim

# -----
# Prompt
# -----

__prompt_git_branch_name(){
	local branch=$(git branch --show-current 2>/dev/null)
	if [ -n "$branch" ]; then
		echo " $branch"
	fi
}

export PS1="\n\u@\h \D{%F %T}\[\033[32m\]\$(__prompt_git_branch_name)\[\033[0m\] \w\n\$ "

# -----
# Alias
# -----

alias apply='cd ~/setup/ && ./install.sh && cd - && . ~/.bashrc'
alias bashrc='nvim ~/setup/.bashrc && apply && setup_fmt'
alias bashlo='nvim ~/.bashrc_local && . ~/.bashrc_local'
alias vimrc='nvim ~/setup/nvim/init.vim && apply'
alias install='nvim ~/setup/install.sh && apply'

alias ls='ls -a'
alias ll='ls -alF --color=auto'
# alias zip='paste'

# -----
# Helper
# -----

setup() {
	cd ~/setup
	local_window
}

setup_fmt() {
	if command -v shfmt >/dev/null; then
		shfmt -w ~/setup/**/*.sh
	fi
}

__confirm() {
	echo -n "$1 (y/N) : "
	read -r yn
	case $yn in
	y | Y)
		echo '実行します'
		return 0
		;;
	*)
		echo '中止しました'
		return 1
		;;
	esac
}

map() {
	while read LINE; do
		"$@" $LINE
	done
}

# {} の位置に標準入力の内容を挿入できる map
# SYMBOL 環境変数で {} を変更可能
each() {
	while read LINE; do
		local template="$*" # 引数を1つの文字列に結合（空白区切り）
		local cmd=$(echo "$template" | sed "s/${SYMBOL:-"{}"}/$LINE/g")
		eval "$cmd"
	done
}

is_wsl() {
	command -v powershell.exe >/dev/null
}

append() {
	cat -
	echo $1
}

stderr() {
	echo $1 >&2
}

# # 親プロセスのコマンド名
# parent_process_name(){
#   ps -o comm= -p $PPID
# }

# ディレクトリを遡ってファイル検索
find_up() {
	local file="$1"
	local dir="$PWD"
	while [ "$dir" != "/" ]; do
		if [ -e "$dir/$file" ]; then
			echo "$dir/$file"
			return 0
		fi
		dir=$(dirname "$dir")
	done
	return 1
}

# .bashrc_project を編集して読み込み
bashpr() {
	local path=$(find_up .bashrc_project)
	if [ -n "$path" ]; then
		nvim "$path"
		source "$path"
	fi
}

# $1 のファイルが $2 の権限であるかを検証
# example: is_file_permission path/to/file 600
is_file_permission() {
	local path=$1
	local expect=$2
	local actual=$(stat -c "%a" "$path")
	if [ "$expect" = "$actual" ]; then
		return 0
	else
		return 1
	fi
}

asdf_add() {
	local name=$1
	local version=${2:-latest}

	asdf plugin add "$name" &&
		asdf install "$name" "$version" &&
		asdf global "$name" "$version"
}

asdf_remove() {
	local name=$1
	asdf plugin remove "$name"
	asdf reshim
}

# 標準出力の内容をクリップボードに
yank() {
	if is_wsl; then
		iconv -t cp932 | clip.exe
	else
		stderr "非対応です"
	fi
}

# rg で検索し、置換する
rgsed() {
	read -p "検索クエリを入力してください: " query
	read -p "置換する文字列を入力してください: " replace
	mapfile -t results < <(rg --vimgrep "$query")
	for line in "${results[@]}"; do
		_rgsed $line
	done
}

_rgsed() {
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
	n) ;;
	e)
		nvim +$lineno "$file"
		_rgsed $line
		;;
	*)
		_rgsed $line
		;;
	esac
}

# -----
# llm
# -----

HAIKU='claude-3-5-haiku-latest'
SONNET='claude-3-7-sonnet-latest'
anthropic_cli() {
	local message=$(cat -)
	local model=${1:-$HAIKU}
	local tmpfile=$(mktemp)

	ANTHROPIC_API_KEY="$(secret_get anthropic)"

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

if command -v ollama >/dev/null; then
	# ollama サーバーが起動してなかったら起動する
	pgrep -f "ollama serve" > /dev/null || { nohup ollama serve > ~/ollama.log 2>&1 & }

	alias ollama_log="less ~/ollama.log"

	ollama_cli(){
		local model=${1:-'gemma3:4b'}
		cat | ollama run $model
	}
fi

alias llm="anthropic_cli"

# -----
# tmux
# -----

alias tmuxrc='nvim ~/setup/.tmux.conf && apply'

# window の色を変更する
alias color_red="tmux select-pane -P 'bg=#350000,fg=white'"
alias color_green="tmux select-pane -P 'bg=#003500,fg=white'"
alias color_black="tmux select-pane -P 'bg=black,fg=white'"

# window の色と名前を変更する
change_window() {
	eval color_$1
	tmux rename-window $2
}

tmux_split() {
	tmux split-window -h \; \
		split-window -v \; \
		select-pane -t 0 \; \
		split-window -v
}

# -----
# プロジェクト管理
# -----

# プロジェクト名を取得する
project_name() {
	local path=$(find_up .bashrc_project)
	if [ -n "$path" ]; then
		echo "$(basename $(dirname $(find_up .bashrc_project)))"
	else
		echo "home"
	fi
}

# window の色と名前をローカルの設定にする
local_window() {
	color_black
	tmux rename-window "$(project_name)"
}

# .bashrc_project を読み込む
load_project() {
	local path=$(find_up .bashrc_project)
	if [ -n "$path" ]; then
		source "$path"
	fi
}

# PROMPT_COMMAND に設定されたコマンドは、すべてのコマンド実行後に毎回実行されます。
PROMPT_COMMAND='load_project'

# -----
# Sound
# -----

beep() {
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

beep_beep() {
	local lag="[console]::beep(37,2000);" # ラグ対策に無音に近い音を2秒
	local do="[console]::beep(440,500);"  # ド
	local re="[console]::beep(494,500);"  # レ
	local mi="[console]::beep(554,500);"  # ミ
	powershell.exe -Command $lag$mi$re$do
}

beep_good() {
	local lag="[console]::beep(37,2000);" # ラグ対策に無音に近い音を2秒
	local do="[console]::beep(440,100);"  # ド
	local re="[console]::beep(494,100);"  # レ
	local res="[console]::beep(523,100);" # レ#
	local mi="[console]::beep(554,100);"  # ミ
	local fa="[console]::beep(587,100);"  # ファ
	local fas="[console]::beep(622,100);" # ファ#
	local so="[console]::beep(659,100);"  # ソ
	local sos="[console]::beep(699,100);" # ソ#
	local ra="[console]::beep(740,100);"  # ラ
	local si="[console]::beep(831,100);"  # シ
	powershell.exe -Command $lag$fas$fa$re$sos$so$res$so$si
}

beep_bad() {
	local lag="[console]::beep(37,2000);" # ラグ対策に無音に近い音を2秒
	local do="[console]::beep(440,100);"  # ド
	local re="[console]::beep(494,100);"  # レ
	local mi="[console]::beep(554,100);"  # ミ
	local fa="[console]::beep(587,100);"  # ファ
	local fa="[console]::beep(622,100);"  # ファ#
	local so="[console]::beep(659,100);"  # ソ
	local ra="[console]::beep(740,100);"  # ラ
	local si="[console]::beep(831,100);"  # シ
	powershell.exe -Command $lag$si$fa$fa$fa$mi$re$do
}

# simple sound
beep_success() {
	local lag="[console]::beep(37,2000);" # ラグ対策に無音に近い音を2秒
	local fa="[console]::beep(587,100);"  # ファ
	local si="[console]::beep(831,100);"  # シ
	powershell.exe -Command $lag$fa$si$si
}

# simple sound
beep_fail() {
	local lag="[console]::beep(37,2000);" # ラグ対策に無音に近い音を2秒
	local do="[console]::beep(440,100);"  # ド
	local fa="[console]::beep(587,100);"  # ファ
	powershell.exe -Command $lag$fa$do$do
}

# -----
# Secret Manager
# -----

export SECRET_DATA_PATH="/home/kekemoto/.secret_data.gpg"

# 標準入力を gpg で暗号化して標準出力する
# gpg_passphrease : gpg で使うパスワード
__encrypt() {
	gpg --batch --passphrase $1 --symmetric
}

# 標準入力を gpg で復号化して標準出力する
# gpg_passphrease : gpg で使うパスワード
__decrypt() {
	gpg --batch --passphrase $1 --quiet --decrypt
}

# 標準入力を暗号化して $SECRET_DATA_PATH に出力
__secret_encrypt() {
	if [ -z "$GPG_PASSWORD" ]; then
		stderr "\$GPG_PASSWORD が設定されてません"
		return 1
	fi

	__encrypt $GPG_PASSWORD >$SECRET_DATA_PATH
}

# $SECRET_DATA_PATH を復号化して標準出力
__secret_decrypt() {
	if [ -z "$GPG_PASSWORD" ]; then
		stderr "\$GPG_PASSWORD が設定されてません"
		return 1
	fi
	if [ ! -e "$SECRET_DATA_PATH" ]; then
		stderr "$SECRET_DATA_PATH にファイルがありません"
		return 1
	fi
	if ! is_file_permission "$SECRET_DATA_PATH" 600; then
		stderr "$SECRET_DATA_PATH の権限が 600 ではありません"
		return 1
	fi

	cat $SECRET_DATA_PATH | __decrypt $GPG_PASSWORD
}

secret_init() {
	read -s -p "GPG_PASSWORD: " GPG_PASSWORD
}

# 秘密情報を追加
# key: あとで取り出すためのキー。任意文字列
# secret: 秘密情報
secret_add() {
	if [ "$#" != 2 ]; then
		stderr "引数の数が合っていません。"
		return 1
	fi
	local key=$1
	local secret=$2

	if [ ! -e "$SECRET_DATA_PATH" ]; then
		echo "$key $secret" | __secret_encrypt
		return 0
	fi

	local value=$(__secret_decrypt)
	value+="
$key $secret"
	echo "$value" | __secret_encrypt
}

# 秘密情報を取得
# key: 欲しい秘密情報のキー
secret_get() {
	local key=${1:-default}

	local value=$(__secret_decrypt | awk -v key="$key" '$1 == key {print $2; exit}')

	if [ -z "$value" ]; then
		stderr "秘密情報が見つかりませんでした。"
		return 1
	else
		echo "$value"
	fi
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
alias gca='git commit --amend'
alias gcb='git commit -m backup --no-verify'
alias gb='git branch'
alias gbr='git for-each-ref --format="%(refname:short) %(upstream:short)" refs/heads/ | column -t'
alias gd='git diff @'
alias gd1='git diff @~ @'

gl() {
	local num
	if [ -z $1 ]; then
		num=3
	else
		num=$1
	fi

	git log --reverse -n $num
}

gan() {
	# git ls-files --others --exclude-standard -z | xargs -0 git add -N
	git add -AN
}

gap() {
	gan
	git add -p "$@"
}

gcm() {
	git commit -m "$(make_git_commit_message)" && git commit --amend
}

make_git_commit_message() {
	git diff --staged | append "上記の差分の内容から git commit のメッセージを考えてください。一行目に概要を短く書き、空行を入れてから詳細を書いてください。それを日本語でコミットメッセージだけを直接出力してください" | llm
}

grs() {
	__confirm "git reset --soft を実行しますか？" &&
		git reset --soft HEAD~
}

grh() {
	__confirm "git reset --hard を実行しますか？" &&
		git add -A &&
		git reset --hard HEAD
}

gpull() {
	gf
	git pull
}

g_rebase() {
	local now=$(git branch --show-current)
	git switch main &&
		gpull &&
		git switch $now &&
		git rebase main
}

g_save() {
	git stash push -u
}

g_pop() {
	git stash pop
}

g_code_review() {
	local branch=$1
	local model=$2 # 空でもOK
	git log -p remotes/origin/main..remotes/origin/"$branch" | append '上記の内容からコードレビューして' | llm "$model"
}

g_branch_all_delete() {
	local branch=${1:-main}
	git switch main &&
		gpull &&
		git branch | map git branch -d
}

g_project_switch() {
	local project_name="${1//\//_}"
	local base_dir="$HOME/work/dev"

	if [[ -z "$project_name" ]]; then
		stderr "Usage: cl_switch <project_name>"
		stderr "Example: cl_switch myapp"
		stderr "         (clones current repo to ~/dev/myapp and switches to it)"
		return 1
	fi

	local old_project_dir=$(pwd)

	# カレントディレクトリからリモートURLを取得
	local repo_url=$(git remote get-url origin 2>/dev/null)
	if [[ -z "$repo_url" ]]; then
		stderr "Error: Current directory is not a git repository with origin remote."
		return 1
	fi

	# プロジェクトディレクトリが存在しない場合はコピーする
	local project_dir="$base_dir/$project_name"
	if [[ ! -d "$project_dir" ]]; then
		mkdir -p "$base_dir"
		cp -R "$old_project_dir" "$project_dir"
	fi

	cd "$project_dir" || return 1

	if [ "$repo_url" != "$(git remote get-url origin 2>/dev/null)" ]; then
		stderr "Error: リポジトリが一致しませんでした。別リポジトリのブランチ名と衝突した可能性があります"
		return 1
	fi

	# ブランチが存在するかチェック
	if git show-ref --verify --quiet "refs/heads/$project_name"; then
		git switch "$project_name"
	else
		git switch -c "$project_name"
	fi
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
alias dcul="dcu && dcl"
alias dcs="docker compose stop"
alias dcd="docker compose down -t 5"
alias dcl="docker compose logs -f"
# alias dcr="docker compose restart -t 5"

de() {
	if [ -z $2 ]; then
		docker exec -it $1 bash
	else
		docker exec -it $1 $2
	fi
}

dd() {
	echo start
	docker container stop -t 5 $1 >/dev/null
	echo container stoped $1
	docker container rm $1 >/dev/null
	echo container removed $1
	if [ ! -z $2 ]; then
		docker image rm $2 >/dev/null
		echo image removed $2
	fi
}

# -----
# fzf
# -----

# https://raw.githubusercontent.com/junegunn/fzf/master/shell/key-bindings.bash
source ~/setup/key-bindings.sh

fcd() {
	cd ~
	if [ -z $1 ]; then
		cd $(fd . | fzf)
	else
		cd $(fd . | fzf --query $1)
	fi
}
# -----
# asdf
# -----

. "$HOME/.asdf/asdf.sh"

# asdf_add shfmt
# asdf_add redis-cli

# -----
# その他設定
# -----

# ** のグロブ展開を可能にする
shopt -s globstar

# .bashrc_local の権限をバリデーション
BASHRC_LOCAL="$HOME/.bashrc_local"
if [ -f "$BASHRC_LOCAL" ]; then
	if is_file_permission "$BASHRC_LOCAL" 600; then
		source "$BASHRC_LOCAL"
	else
		stderr "$BASHRC_LOCAL の権限が 600 ではありません"
	fi
fi
