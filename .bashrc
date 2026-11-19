export HISTSIZE=10000
export HISTFILESIZE=10000
export HISTCONTROL=ignoredups:ignorespace

export COLOR_RED="\e[31m"
export COLOR_GREEN="\e[32m"
export COLOR_YELLOW="\e[33m"
export COLOR_BLUE="\e[34m"
export COLOR_END="\e[m"

export EDITOR=nvim
export LESS='-M -R -F -X'

# -----
# Prompt
# -----

__prompt_git_branch_name(){
	local branch=$(git branch --show-current 2>/dev/null)
	if [ -n "$branch" ]; then
		echo " $branch"
	fi
}

export PS1="\n\u \[\033[32m\]\h\[\033[0m\] \D{%F %T}\[\033[33m\]\$(__prompt_git_branch_name)\[\033[0m\] \w\n\$ "

# -----
# Alias
# -----

alias apply='cd ~/setup/ && ./install.sh && cd - && . ~/.bashrc'
alias bashrc='nvim ~/setup/.bashrc && apply && setup_fmt'
alias bashlo='nvim ~/.bashrc_local && . ~/.bashrc_local'
alias vimrc='nvim ~/setup/nvim/init.vim && apply'
alias install='nvim ~/setup/install.sh && apply'

alias ls='ls -a --color=auto'
alias ll='ls -alhF --color=auto'
alias tree='tree --gitignore'
alias cl='claude'
alias clc='claude --continue'
alias clr='claude --resume'
# alias zip='paste'

alias sudoer='~/setup/bin/sudoer'
alias ssher='~/setup/bin/ssher'

# -----
# Helper
# -----

setup() {
	cd ~/setup
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


# 空行を出力するだけ。画面を区切りたい時に
blank(){
  local count=${1:-40}  # 引数がなければデフォルト10回
  for i in $(seq 1 "$count"); do
    echo ""
  done
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
	echo "$1" >&2
}

# # 親プロセスのコマンド名
# parent_process_name(){
#   ps -o comm= -p $PPID
# }

# ディレクトリを遡ってファイル検索
find_up() {
	local file="$1"
	local dir="${2:-$PWD}"
	[[ "$dir" == /* ]] || dir="$PWD/$dir" # 相対パスだと / に届かず止まらないため
	while [ "$dir" != "/" ]; do
		if [ -e "$dir/$file" ]; then
			echo "$dir/$file"
			return 0
		fi
		dir=${dir%/*}
		dir=${dir:-/}
	done
	return 1
}

# .bashrc_project のパスを取得する
# 見つからず git worktree の中にいる場合は、メインの worktree から探す
_find_project_file() {
	find_up .bashrc_project && return 0
	local dotgit main
	# PROMPT_COMMAND から毎回呼ばれるので、git を起動するのは .git がファイル（linked worktree）のときだけにする
	# .git がディレクトリならメインの worktree の中にいるので探索済み
	dotgit=$(find_up .git) && [ -f "$dotgit" ] || return 1
	# メインの worktree は一覧の先頭（common_dir の親とは限らない）
	read -r _ main < <(git worktree list --porcelain 2>/dev/null)
	[ -n "$main" ] || return 1
	find_up .bashrc_project "$main"
}

# .bashrc_project を編集して読み込み
bashpr() {
	local path=$(_find_project_file)
	if [ -n "$path" ]; then
		nvim "$path"
		_check_600 "$path" && source "$path"
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

# source してよいファイル（権限が 600）か検証する。違えば警告して 1 を返す
# シンボリックリンクはリンク自身の権限（777）で判定されるので常に弾く（clone したリポジトリ経由で任意のファイルを読ませないため）
# source は呼び出し側で行う（関数内で source すると declare がローカル変数になるため）
_check_600() {
	is_file_permission "$1" 600 && return 0
	stderr "$1 の権限が 600 ではありません"
	return 1
}

mise_add() {
	local name=$1
	local version=${2:-latest}

	mise use --global "$name@$version"
}

mise_remove() {
	local name=$1
	mise uninstall "$name"
}

# インストール済みのツールを最新版に更新する
mise_upgrade() {
	mise upgrade
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
	local query=$1
	local replace=$2

	if [ -z "$query" ]; then
		stderr "検索文字列が設定されてません"
		return 1
	fi
	if [ -z "$replace" ]; then
		stderr "置換文字列が設定されてません"
		return 1
	fi

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

# 標準入力のファイル一覧を nvim のタブで開く
nvimp() {
	xargs nvim -p
}

# 行数の指定付きのパスを開く
nvimg() {
  case "$1" in
    *:*) nvim "+${1##*:}" "${1%:*}" ;;
    *)   nvim "$1" ;;
  esac
}

# rg の結果を nvim で開く
vrg() {
	rg "$@" -l | xargs nvim +"/$1" -p
}

# rg の結果を fzf でファイル選択して nvim で開く
frg() {
	local file=$(rg "$@" -l | fzf)
	[ -z "$file" ] && return 1
	nvim +"/$1" "$file"
}

# 自分のグローバルIPを確認する
check_my_ip() {
	curl http://checkip.amazonaws.com
}

# 差分を見やすいようにする
dif() {
	# あんま使わないから delta はデフォルトでは入れてない
	diff -u "$1" "$2" | delta "${@:3}"
}
difs() {
	# あんま使わないから delta はデフォルトでは入れてない
	diff -u "$1" "$2" | delta --side-by-side "${@:3}"
}

ssh_hosts(){
	cat ~/.ssh/config | grep '^Host ' | grep -v '\*' | awk '{print $2}'
}

# -----
# llm
# -----

HAIKU='claude-haiku-4-5'
SONNET='claude-sonnet-4-5'
anthropic_api() {
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

# models: haiku, sonnet, opus
claude_code() {
	local model=${1:-sonnet}
	claude -p --settings '{"disableAllHooks":true}' --strict-mcp-config --mcp-config "" --disable-slash-commands --model "$model"
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

alias llm="claude_code"

# -----
# herdr
# -----

# 保存後、起動中の herdr にも設定を反映する
alias herdrrc='nvim ~/setup/herdr/config.toml && apply && { [ -z "$HERDR_PANE_ID" ] || herdr server reload-config >/dev/null; }'

# pane の色を変更する（OSC 10/11 で文字色・背景色を設定し、OSC 110/111 で元に戻す）
_pane_color() {
	[ -z "$HERDR_PANE_ID" ] && return 0
	if [ -n "$1" ]; then
		printf '\e]11;%s\a\e]10;white\a' "$1"
	else
		printf '\e]111\a\e]110\a'
	fi
}
alias color_red='_pane_color "#350000"'
alias color_green='_pane_color "#003500"'
alias color_black='_pane_color'

# tab の名前を変更する
tab_rename() {
	[ -z "$HERDR_TAB_ID" ] || [ -z "$1" ] || herdr tab rename "$HERDR_TAB_ID" "$1" >/dev/null
}

# pane の色と tab の名前を変更する
change_window() {
	eval color_$1
	tab_rename "$2"
}

# 名前付きセッションに入る。無ければカレントディレクトリで作る（tmux new-session -A 相当）
# 停止中のセッションは保存済みのレイアウトと cwd で復元され、カレントディレクトリが無視されるので破棄して作り直す
herdr_session() {
	local name=$1
	if [ -n "$HERDR_PANE_ID" ]; then
		stderr "herdr の中では入れ子にできません"
		return 1
	fi
	# default の session_dir は ~/.config/herdr そのものなので、削除対象にしない
	if [ -z "$name" ] || [ "$name" = default ]; then
		stderr "Usage: herdr_session <name>（default 以外）"
		return 1
	fi
	# jq -e: 0=起動中 1=停止中または未作成 それ以外=一覧の取得に失敗（削除せず中止する）
	herdr session list --json | jq -e --arg n "$name" 'any(.sessions[]; .name == $n and .running)' >/dev/null
	case $? in
	0) ;;
	1) herdr session delete "$name" >/dev/null 2>&1 ;;
	*)
		stderr "herdr のセッション一覧を取得できませんでした"
		return 1
		;;
	esac
	herdr --session "$name"
}

# 今いるセッションを終了する（中のシェルもすべて終了する）
alias hss='herdr server stop'

# pane を 4 分割する
herdr_split() {
	[ -n "$HERDR_PANE_ID" ] || return 1
	local right
	right=$(herdr pane split "$HERDR_PANE_ID" --direction right --no-focus | jq -er '.result.pane.pane_id') || return 1
	herdr pane split "$right" --direction down --no-focus >/dev/null || return 1
	herdr pane split "$HERDR_PANE_ID" --direction down --no-focus >/dev/null
}

# -----
# プロジェクト管理
# -----

# プロジェクト名を取得する
project_name() {
	local path=$(_find_project_file)
	if [ -n "$path" ]; then
		basename "$(dirname "$path")"
	else
		echo "home"
	fi
}

# pane の色と tab の名前をローカルの設定にする
local_window() {
	color_black
	tab_rename "$(project_name)"
}

# .bashrc_project を読み込む（権限が 600 でなければ読み込まない）
load_project() {
	local path=$(_find_project_file)
	[ -n "$path" ] || return 0
	# プロンプトごとに呼ばれるので、権限の警告は同じファイルにつき 1 回だけ出す
	if is_file_permission "$path" 600; then
		_PROJECT_WARNED=
		source "$path"
	elif [ "$_PROJECT_WARNED" != "$path" ]; then
		_PROJECT_WARNED=$path
		_check_600 "$path" # 警告を出すだけ
	fi
	return 0
}

# PROMPT_COMMAND に設定されたコマンドは、すべてのコマンド実行後に毎回実行されます。
#PROMPT_COMMAND='load_project; local_window'
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

# ゼルダの伝説
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
	_check_600 "$SECRET_DATA_PATH" || return 1

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
alias gb='git branch'
alias gbr='git for-each-ref --format="%(refname:short) %(upstream:short)" refs/heads/ | column -t'
alias gd='git diff @'
alias gd1='git diff @~ @'

# git log
gl() {
	local num
	if [ -z $1 ]; then
		num=3
	else
		num=$1
	fi

	git log --reverse -n $num
}

# git add -N
gan() {
	# git ls-files --others --exclude-standard -z | xargs -0 git add -N
	git add -AN "$@"
}

# git add -p
gap() {
	gan
	git add -p "$@"
}

# git commit backup
gcb() {
	local msg='backup'
	if [ ! -z $1 ]; then
		msg="$msg: $1"
	fi
	git commit -m "$msg" --no-verify
}

# git commit message
gcm() {
	git commit -m "$(make_git_commit_message)" && git commit --amend --no-verify
}

make_git_commit_message() {
	git diff --staged -- . ':(exclude)package-lock.json' ':(exclude)worker-configuration.d.ts' | append "上記の差分の内容から git commit のメッセージを考えてください。一行目に概要を短く書き、空行を入れてから詳細を書いてください。それを日本語で**コミットメッセージだけ**を出力してください" | llm
}

# git switch
# 旧版の alias sw=gsw が残ったシェルで apply すると、下の定義が gsw() になってしまうので外す（移行用。旧版のシェルが無くなったら消してよい）
unalias sw 2>/dev/null
sw() {
	local selected branch worktree_dir
	selected="$(git branch --format='%(refname:short)%09%(worktreepath)' |
		fzf --query "$1" --select-1 --delimiter=$'\t' --nth=1)" || return
	branch="${selected%%$'\t'*}"
	worktree_dir="${selected#*$'\t'}"
	if [[ -n "${worktree_dir}" ]]; then
		cd "${worktree_dir}" # worktree にあるブランチなら、その worktree へ移動
	else
		git switch "${branch}" # どの worktree にも無いブランチなら、今いる worktree で switch
	fi
}

# git switch -c
gsc() {
	git switch -c "$@"
}
alias swc=gsc

# git reset --soft
grs() {
	__confirm "git reset --soft を実行しますか？" &&
		git reset --soft HEAD~
}

# git reset --hard
grh() {
	__confirm "git reset --hard を実行しますか？" &&
		git add -A &&
		git reset --hard HEAD
}

gpull() {
	gf
	git pull
}

# git conflict nvim
gcn() {
	git status -s | awk '$1 == "UU" { print $2 }' | xargs nvim +"/=======" -p
}

# git status nvim
gsn() {
	git status -s | awk '$1 != "D" { print $2 }' | xargs nvim -p
}

# git rebase
g_rebase() {
	local branch=${1:-main}
	local now=$(git branch --show-current)
	git switch $branch &&
		gpull &&
		git switch $now &&
		git rebase $branch
}

# git merge
g_merge ()
{
    local branch=${1:-main};
    local now=$(git branch --show-current);
    git switch $branch && gpull && git switch $now && git merge $branch
}

# git stash save
g_save() {
	git stash push -u
}

# git stash pop
g_pop() {
	git stash pop
}

# git diff merge
gdm(){
	git diff @..."$@"
}

g_code_review() {
	local branch=$1
	local model=$2 # 空でもOK
	git log -p remotes/origin/main..remotes/origin/"$branch" | append '上記の内容からコードレビューして' | llm "$model"
}

g_branch_all_delete() {
	local branch=${1:-main}
	git switch $branch && gpull && git branch | awk '{print $1}' | grep -v '*' | xargs git branch -d
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
alias dcl="docker compose logs -f --tail 1000"
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
source ~/setup/scripts/key-bindings.sh

fcd() {
	cd ~
	if [ -z $1 ]; then
		cd $(fd . | fzf)
	else
		cd $(fd . | fzf --query $1)
	fi
}

# fzf git status
fgs() {
	git status -s | awk '{print $2}' | fzf --query "$1" --select-1
}

# fzf git branch
fgb() {
	git branch --format='%(refname:short)' | fzf --query "$1" --select-1
}

# -----
# mise
# -----

export PATH="$HOME/.local/bin:$PATH"
eval "$(mise activate bash)"

# mise_add shfmt
# mise_add redis-cli

# -----
# その他設定
# -----

source ~/setup/scripts/csv_tool.sh
source ~/setup/scripts/trash.sh
source ~/setup/scripts/git_worktree.sh

# ** のグロブ展開を可能にする
shopt -s globstar

# .bashrc_local の権限をバリデーション
BASHRC_LOCAL="$HOME/.bashrc_local"
if [ -f "$BASHRC_LOCAL" ] && _check_600 "$BASHRC_LOCAL"; then
	source "$BASHRC_LOCAL"
fi
