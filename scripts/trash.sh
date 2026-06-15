# 物理削除せずゴミ箱に捨てるようにする
# ゴミ箱に30日以上あったら物理削除する

TRASH_DIR="$HOME/trash"

# 30 日以上前にゴミ箱に入れたデータを削除する
[ -d "$TRASH_DIR" ] && find "$TRASH_DIR" -mindepth 1 -maxdepth 1 -mtime +29 -exec rm -rf {} +

trash() {
	if [ "$#" -eq 0 ]; then
		echo "trash: 引数がありません" >&2
		return 1
	fi

	mkdir -p "$TRASH_DIR"

	local f base target
	for f in "$@"; do
		# オプション(-rf 等)はスキップ。ファイルとして扱わない
		case "$f" in
		-*) continue ;;
		esac

		if [ ! -e "$f" ] && [ ! -L "$f" ]; then
			echo "trash: '$f' は存在しません" >&2
			continue
		fi

		if ! _trash_check "$f"; then
			continue
		fi

		# 末尾スラッシュを除去してから basename を取る
		base=$(basename "${f%/}")
		target="$TRASH_DIR/$base"

		# 同名衝突したらタイムスタンプを付与
		if [ -e "$target" ]; then
			target="$TRASH_DIR/${base}.$(date +%Y%m%d_%H%M%S_%N)"
		fi

		mv -- "$f" "$target"
		touch "$target"
	done
}

# 非破壊で trash 可能かを判定。OK:0 / NG:理由を出して非0
_trash_check() {
	local f="$1" parent
	if [ ! -e "$f" ] && [ ! -L "$f" ]; then
		echo "trash: '$f' は存在しません" >&2
		return 1
	fi
	parent=$(dirname -- "${f%/}")
	if [ ! -w "$parent" ] || [ ! -x "$parent" ]; then
		echo "trash: 親 '$parent' に書き込み権限なし（sudo_trash を検討）" >&2
		return 1
	fi
	if [ ! -w "$TRASH_DIR" ] || [ ! -x "$TRASH_DIR" ]; then
		echo "trash: TRASH_DIR '$TRASH_DIR' に書き込めません" >&2
		return 1
	fi
	return 0
}

sudo_trash() {
	sudo bash -c "$(declare -f _trash_check trash); TRASH_DIR='$TRASH_DIR' trash \"\$@\"" _ "$@" &&
		sudo chown -R "$(id -u):$(id -g)" "$TRASH_DIR"
}
