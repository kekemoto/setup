#!/usr/bin/env bash
set -eu

require_command() {
	local command=$1

	if ! command -v $command >/dev/null; then
		echo "$command がインストールされていません"
		exit 1
	fi
}

# ---------
# メイン
# ---------

# 実行しているパスが正しいか（リポジトリは ~/setup にある前提）
if [ "$(pwd)" != "$HOME/setup" ]; then
	echo "~/setup で実行してください"
	exit 1
fi

# 必要なコマンド（mise の導入に使う）
require_command git
require_command curl
require_command gcc
require_command unzip

# デフォルトのシェルを変更
# （$SHELL ではなく、ログインシェルとして登録されている値で判定する。/usr/bin/bash も bash として扱う）
case "$(getent passwd "$(id -un)" | cut -d: -f7)" in
*/bash) ;;
*)
	chsh -s /bin/bash
	;;
esac

# Ubuntu で Python をビルドするときに要るパッケージ
# sudo apt install -y libffi-dev libncurses5-dev zlib1g zlib1g-dev libssl-dev libreadline-dev libbz2-dev libsqlite3-dev

# mise を導入する（mise は ~/.local/bin に入るので、先に PATH に足してから有無を確かめる）
export PATH="$HOME/.local/bin:$PATH"
if ! command -v mise >/dev/null; then
	curl -fsSL https://mise.run | sh
	require_command mise # 導入に失敗していたらここで止める
fi

# ツールチェインをインストールし、グローバルに設定する
# @latest を指定すると最新の安定版をインストールする
tools=(
	python@latest
	aqua:neovim/neovim@latest # vfox 版はシェル起動のたびの mise の処理が遅いので aqua 版を使う
	herdr@latest
	node@latest
	jq@latest
	fzf@latest
	fd@latest
	ripgrep@latest
	uv@latest # pipx バックエンド（mycli）が使う
	pipx:mycli@latest
	# redis-cli@latest
	# zig@latest
	# zls@latest
)

# 「名前@要求版」が同じものは飛ばす（更新したいときは mise_upgrade を使う。要求版を書き換えたものは入れ直す）
installed=$(mise ls --global --installed 2>/dev/null | awk '{print $1 "@" $4}')

targets=()
for tool in "${tools[@]}"; do
	if ! grep -qxF "$tool" <<<"$installed"; then
		targets+=("$tool")
	fi
done

if [ ${#targets[@]} -ne 0 ]; then
	mise use --global --yes "${targets[@]}"
fi

# bash
cp -fp --remove-destination ./.bashrc $HOME/ # ~/.bashrc がシンボリックリンクでも、リンク先ではなくリンクを置き換える

# herdr・Neovim（~/.config/herdr・~/.config/nvim に中身をマージしてコピーする）
mkdir -p "$HOME/.config"
cp -rfp ./herdr ./nvim $HOME/.config/

# vim-plug
plug="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/autoload/plug.vim"
if [ ! -e "$plug" ]; then
	curl -fLo "$plug" --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

# git
completion="$HOME/.config/git/git-completion.bash"
if [ ! -e "$completion" ]; then
	curl -fsSL --create-dirs -o "$completion" "https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash"
fi
git config --global commit.template ~/setup/.gitmessages
git config --global alias.pushf 'push --force-with-lease --force-if-includes'
# 引数が無ければ全部、あれば指定したファイルだけをステージから外す
git config --global alias.unstage '!f() { cd "${GIT_PREFIX:-.}" && git restore --staged -- "${@:-:/}"; }; f'
git config --global --replace-all --bool push.autoSetupRemote true
git config --global mergetool.keepBackup false

# git diff-highlight（無ければ git の contrib から入れて pager に設定する）
# すでに入っている環境では pager を変えない（delta など、別の pager を設定済みのことがあるため）
highlight=/usr/share/doc/git/contrib/diff-highlight/diff-highlight
if ! command -v diff-highlight >/dev/null && [ -e "$highlight" ]; then
	install -D -m 755 "$highlight" $HOME/.local/bin/diff-highlight
	git config --global pager.log "diff-highlight | less"
	git config --global pager.show "diff-highlight | less"
	git config --global pager.diff "diff-highlight | less"
fi

echo "完了"
