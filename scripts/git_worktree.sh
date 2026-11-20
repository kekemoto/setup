# git worktree の補助関数
# 依存: git, fzf

# 本体リポジトリ（メインの worktree）のルート。worktree 内からでも取れる
# git worktree list の先頭がメイン（--git-common-dir の親とは限らない。--separate-git-dir の場合など）
_gw_repo_root() {
	local line
	IFS= read -r line < <(git worktree list --porcelain 2>/dev/null) # パスの前後の空白も残す（cd のたびに呼ばれるので awk を通さない）
	[[ $line == "worktree "?* ]] && echo "${line#worktree }"
}

# worktree を「パス<TAB>ブランチ<TAB>状態」の形で 1 行ずつ出す（先頭がメイン。ブランチが無ければ (detached) か (bare)）
# git worktree list の表示からはパスの区切りが分からない（パスに空白があると切れない）ので --porcelain から作る
_gw_list() {
	git worktree list --porcelain | awk '
		# ブランチが無いときは (detached) や (bare) を入れる（空の欄だと、タブ区切りの read で列が詰まってずれる）
		function flush() { if (dir != "") printf "%s\t%s\t%s\n", dir, branch, flags; dir = ""; branch = "(detached)"; flags = "" }
		BEGIN { flush() }
		/^worktree / { flush(); dir = substr($0, 10) }
		/^branch / { branch = substr($0, 8); sub(/^refs\/heads\//, "", branch) }
		/^bare$/ { branch = "(bare)" }
		/^(locked|prunable)/ { flags = flags $1 " " }
		END { flush() }'
}

_gw_not_repo() {
	echo "git リポジトリ内で実行してください" >&2
	return 1
}

gws() {
	_gw_repo_root >/dev/null || _gw_not_repo || return
	local line
	line=$(_gw_list | grep -v $'\t(bare)\t' | fzf --prompt="switch> " --query "$1" --select-1) || return 0
	cd "${line%%$'\t'*}"
}

# 削除: fzf で選んで worktree + ブランチを削除 (本体は候補から除外して保護)
gwd() {
	local main
	main=$(_gw_repo_root) || _gw_not_repo || return

	local line dir branch flags
	line=$(_gw_list | tail -n +2 | fzf --prompt="delete> ") || return 0 # 先頭はメイン（削除から保護する）
	IFS=$'\t' read -r dir branch flags <<<"$line"

	if [[ $flags == *locked* ]]; then # 強制でも消さない。消すなら git worktree unlock してから
		stderr "ロックされているので削除しません: $dir"
		return 1
	fi
	__confirm "削除: $dir [$branch] よろしいですか?" || return 0

	# 削除対象の中にいたら先に本体へ移る（WSL の /mnt/c などでは、cwd になっているディレクトリは消せない）
	# 以降の git はすべて -C で場所を指定するので、cd に失敗して $HOME にいても動く
	case "$PWD/" in "$dir"/*) cd "$main" 2>/dev/null || cd "$HOME" ;; esac
	# ディレクトリを手で消した worktree（prunable）も remove で記録だけ片付く
	if ! git -C "$main" worktree remove "$dir"; then
		# 未コミットの変更・未追跡ファイル・サブモジュールがあると消せない。上の理由と変更を見せて、強制してよいか確かめる
		[ -d "$dir" ] && git -C "$dir" status --short
		__confirm "上の理由で削除できませんでした。変更を破棄して削除しますか?" || return 0
		git -C "$main" worktree remove --force "$dir" || {
			stderr "worktree の削除に失敗しました"
			return 1
		}
	fi

	if [[ $branch != "("* ]] && ! git -C "$main" branch -d "$branch" 2>/dev/null; then # (detached) や (bare) はブランチではない
		if __confirm "ブランチ '$branch' は未マージです。強制削除しますか?"; then
			git -C "$main" branch -D "$branch"
		else
			echo "ブランチは残しました: $branch"
		fi
	fi
}
