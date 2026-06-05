# git worktree helpers (既存リポジトリそのまま)
# 依存: git, fzf / 置き場所: $GW_ROOT/<repo名>/<branch> (デフォルト ~/worktrees)

# 本体リポジトリのルート (worktree 内からでも取れる)
_gw_repo_root() {
	local common
	common=$(git rev-parse --git-common-dir 2>/dev/null) || return 1
	dirname "$(cd "$common" && pwd)"
}

# worktree 置き場 ($GW_ROOT/<repo名>)
_gw_wt_root() {
	local root
	root=$(_gw_repo_root) || return 1
	printf '%s/%s' "${GW_ROOT:-$HOME/worktrees}" "$(basename "$root")"
}

# 切替: 本体 + 全 worktree から fzf で選んで cd
gws() {
	git rev-parse --git-dir >/dev/null 2>&1 || {
		echo "git リポジトリ内で実行してください" >&2
		return 1
	}
	local dir
	dir=$(git worktree list | fzf --prompt="switch> " | awk '{print $1}') || return 0
	[ -n "$dir" ] && cd "$dir"
}

# 作成: $GW_ROOT/<repo名>/<branch> に worktree を生やす (ローカル/リモート/新規を自動判定)
gwc() {
	local name="$1"
	[ -z "$name" ] && {
		echo "usage: gwc <branch>" >&2
		return 1
	}

	local root dir
	root=$(_gw_wt_root) || {
		echo "git リポジトリ内で実行してください" >&2
		return 1
	}
	dir="$root/$(printf '%s' "$name" | tr '/' '-')" # 中間ディレクトリは git が作る

	if [ -e "$dir" ]; then
		: # 既存なら下で cd するだけ
	elif git show-ref --verify --quiet "refs/heads/$name"; then
		git worktree add "$dir" "$name" || return 1
	elif git show-ref --verify --quiet "refs/remotes/origin/$name"; then
		git worktree add --track -b "$name" "$dir" "origin/$name" || return 1
	else
		git worktree add -b "$name" "$dir" || return 1
	fi
	cd "$dir"
}

# 削除: fzf で選んで worktree + ブランチを削除 (本体は候補から除外して保護)
gwd() {
	local main
	main=$(_gw_repo_root) || {
		echo "git リポジトリ内で実行してください" >&2
		return 1
	}

	local line dir branch
	line=$(git worktree list | grep -vF "$main " | fzf --prompt="delete> ") || return 0
	dir=$(printf '%s' "$line" | awk '{print $1}')
	[ -z "$dir" ] && return 0
	branch=$(printf '%s' "$line" | sed -n 's/.*\[\(.*\)\].*/\1/p')

	printf "削除: %s [%s] よろしいですか? [y/N] " "$dir" "${branch:-detached}"
	local ans
	read -r ans
	case "$ans" in y | Y) ;; *)
		echo "中止しました"
		return 0
		;;
	esac

	# 削除対象の中にいたら本体へ退避
	case "$PWD/" in "$dir"/*) cd "$main" 2>/dev/null || cd "$HOME" ;; esac

	git worktree remove "$dir" 2>/dev/null || git worktree remove --force "$dir" || {
		echo "worktree の削除に失敗しました" >&2
		return 1
	}

	if [ -n "$branch" ] && ! git branch -d "$branch" 2>/dev/null; then
		printf "ブランチ '%s' は未マージです。強制削除しますか? [y/N] " "$branch"
		local f
		read -r f
		case "$f" in y | Y) git branch -D "$branch" ;; *) echo "ブランチは残しました: $branch" ;; esac
	fi
}
