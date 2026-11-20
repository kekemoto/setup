# git worktree の補助関数
# 依存: git, fzf

# 本体リポジトリ（メインの worktree）のルート。worktree 内からでも取れる
# git worktree list の先頭がメイン（--git-common-dir の親とは限らない。--separate-git-dir の場合など）
_gw_repo_root() {
	local _ main
	read -r _ main < <(git worktree list --porcelain 2>/dev/null)
	[ -n "$main" ] && echo "$main"
}

_gw_not_repo() {
	echo "git リポジトリ内で実行してください" >&2
	return 1
}

gws() {
	_gw_repo_root >/dev/null || _gw_not_repo || return
	local line
	line=$(git worktree list | fzf --prompt="switch> " --query "$1" --select-1) || return 0
	cd "${line%% *}"
}

# 削除: fzf で選んで worktree + ブランチを削除 (本体は候補から除外して保護)
gwd() {
	local main
	main=$(_gw_repo_root) || _gw_not_repo || return

	local line dir branch=""
	line=$(git worktree list | tail -n +2 | fzf --prompt="delete> ") || return 0 # 先頭はメイン（削除から保護する）
	dir=${line%% *}
	[[ $line =~ \[(.*)\] ]] && branch=${BASH_REMATCH[1]}

	__confirm "削除: $dir [${branch:-detached}] よろしいですか?" || return 0

	# 削除対象の中にいたら本体へ退避
	case "$PWD/" in "$dir"/*) cd "$main" 2>/dev/null || cd "$HOME" ;; esac
	# 以降の git はメインの worktree を基準に実行する（cd に失敗して $HOME にいても動くように）

	if [ ! -d "$dir" ]; then
		# ディレクトリを手で消した worktree（prunable）は、記録だけ片付ける
		git -C "$main" worktree prune
	elif ! git -C "$main" worktree remove "$dir" 2>/dev/null; then
		# 未コミットの変更や未追跡ファイルがあると消せない。中身を見せて、消してよいか確かめる
		git -C "$dir" status --short
		__confirm "未コミットの変更があります。破棄して削除しますか?" || return 0
		git -C "$main" worktree remove --force "$dir" || {
			echo "worktree の削除に失敗しました" >&2
			return 1
		}
	fi

	if [ -n "$branch" ] && ! git -C "$main" branch -d "$branch" 2>/dev/null; then
		if __confirm "ブランチ '$branch' は未マージです。強制削除しますか?"; then
			git -C "$main" branch -D "$branch"
		else
			echo "ブランチは残しました: $branch"
		fi
	fi
}
