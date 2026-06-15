# 物理削除せずゴミ箱に捨てるようにする
# ゴミ箱に30日以上あったら物理削除する

TRASH_DIR="$HOME/trash"

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

sudo_trash() {
	sudo bash -c "$(declare -f trash); TRASH_DIR='$TRASH_DIR' trash \"\$@\"" _ "$@" &&
		sudo chown -R "$(id -u):$(id -g)" "$TRASH_DIR"
}

# 31 日以上前にゴミ箱に入れたデータを削除する
[ -d "$TRASH_DIR" ] && find "$TRASH_DIR" -mindepth 1 -maxdepth 1 -mtime +30 -exec rm -rf {} +
