#!/usr/bin/env bash
set -eu

# mise へ移行したあと、既存の asdf 環境を削除するためのスクリプト。
# 削除前に asdf で管理していたツール一覧を表示する。

ASDF_DIR="$HOME/.asdf"
ASDF_BIN="$ASDF_DIR/bin/asdf"

# asdf がインストールされているか確認
if [ ! -d "$ASDF_DIR" ]; then
	echo "asdf は見つかりませんでした（$ASDF_DIR が存在しない）。何もしません。"
	exit 0
fi

# asdf で管理していたツール一覧を表示
echo "==== asdf で管理していたツール一覧 ===="
if [ -x "$ASDF_BIN" ]; then
	"$ASDF_BIN" list || true
elif [ -f "$HOME/.tool-versions" ]; then
	cat "$HOME/.tool-versions"
else
	echo "（一覧を取得できませんでした）"
fi
echo "======================================"
echo

# 削除の確認
printf "上記の asdf 環境を削除します。よろしいですか? [y/N]: "
read -r answer
case "$answer" in
[yY] | [yY][eE][sS]) ;;
*)
	echo "中止しました。"
	exit 0
	;;
esac

# asdf 本体・プラグイン・シムをまとめて削除
rm -rf "$ASDF_DIR"

# 設定ファイル
rm -f "$HOME/.asdfrc"

# グローバルの .tool-versions は削除せず退避しておく（mise でも参照できるため）
if [ -f "$HOME/.tool-versions" ]; then
	mv "$HOME/.tool-versions" "$HOME/.tool-versions.asdf.bak"
	echo "~/.tool-versions を ~/.tool-versions.asdf.bak に退避しました。"
fi

echo "asdf を削除しました。'exec bash' で新しいシェルを開いて反映してください。"
