# 物理削除せずゴミ箱に捨てるようにする
# ゴミ箱に30日以上あったら物理削除する

TRASH_DIR="$HOME/trash"

# 30 日以上前にゴミ箱に入れたデータを削除する（.bashrc が対話シェルの起動時に呼ぶ）
# 書き込み権限の無いディレクトリ（Go のモジュールキャッシュなど）も消せるよう、先にディレクトリだけ書き込みを許可する
# （chmod は引数に渡したシンボリックリンクをたどってリンク先を変えてしまうので、-type d に限る）
_trash_purge() {
	[ -d "$TRASH_DIR" ] || return 0
	find "$TRASH_DIR" -mindepth 1 -maxdepth 1 -mtime +29 -type d -exec chmod -R u+rwx {} +
	find "$TRASH_DIR" -mindepth 1 -maxdepth 1 -mtime +29 -exec rm -rf {} +
}

trash() {
	if [ "$#" -eq 0 ]; then
		echo "trash: 引数がありません" >&2
		return 1
	fi

	mkdir -p "$TRASH_DIR"
	if [ ! -w "$TRASH_DIR" ] || [ ! -x "$TRASH_DIR" ]; then
		echo "trash: TRASH_DIR '$TRASH_DIR' に書き込めません" >&2
		return 1
	fi

	local f base target rc=0 opts_done=0
	for f in "$@"; do
		# オプション(-rf 等)はスキップ。ファイルとして扱わない（-- より後ろは - で始まってもファイル）
		if ((! opts_done)); then
			case "$f" in
			--) opts_done=1 && continue ;;
			-*) continue ;;
			esac
		fi
		f=${f%/} # 末尾の / を落とす（ディレクトリへのリンクを mylink/ と渡されたときも、リンク自体を扱う）

		_trash_check "$f" || {
			rc=1
			continue
		}

		base=$(basename -- "$f")
		target="$TRASH_DIR/$base"

		# 同名衝突したらタイムスタンプを付与
		if [ -e "$target" ] || [ -L "$target" ]; then
			target="$TRASH_DIR/${base}.$(date +%Y%m%d_%H%M%S_%N)"
		fi

		if mv -- "$f" "$target"; then
			touch -h "$target" # リンクはリンク自身の時刻を更新する（リンク先を書き換えない）
			# sudo_trash（sudo で実行中）なら、移したものだけを呼び出したユーザーの所有に戻す（root のままだと 30 日後の削除が失敗する）
			[ -z "${SUDO_UID:-}" ] || chown -hR "$SUDO_UID:$SUDO_GID" "$target"
		else
			rc=1
		fi
	done
	return "$rc"
}

# 非破壊で trash 可能かを判定。OK:0 / NG:理由を出して非0
_trash_check() {
	local f="$1" parent
	if [ ! -e "$f" ] && [ ! -L "$f" ]; then
		echo "trash: '$f' は存在しません" >&2
		return 1
	fi
	parent=$(dirname -- "$f")
	if [ ! -w "$parent" ] || [ ! -x "$parent" ]; then
		echo "trash: 親 '$parent' に書き込み権限なし（sudo_trash を検討）" >&2
		return 1
	fi
}

sudo_trash() {
	# ゴミ箱は自分の権限で作っておく（root で作られると、以降の trash が使えなくなる）
	mkdir -p "$TRASH_DIR" || return
	sudo bash -c "$(declare -f _trash_check trash); TRASH_DIR=$(printf %q "$TRASH_DIR") trash \"\$@\"" _ "$@"
}
