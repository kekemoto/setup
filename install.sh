#!/usr/bin/env bash
set -eu

require_command() {
	local command=$1

	if ! command -v $command >/dev/null; then
		echo "$command is not install."
		exit 1
	fi
}

# ---------
# メイン
# ---------

# 実行しているパスが正しいか
if [ $(pwd) != "$HOME/setup" ]; then
	echo "The setup location is different."
	exit 1
fi

# 必要なコマンドが入っているか

# for install mise
require_command git
require_command curl
require_command gcc
# for install tmux
require_command make
require_command unzip

# デフォルトのシェルを変更
if [ "$SHELL" != "/bin/bash" ]; then
	chsh -s /bin/bash
fi

# for Python on Ubuntu
# sudo apt install -y libffi-dev libncurses5-dev zlib1g zlib1g-dev libssl-dev libreadline-dev libbz2-dev libsqlite3-dev

# install mise
if ! command -v mise >/dev/null; then
	curl https://mise.run | sh
fi
export PATH="$HOME/.local/bin:$PATH"

# ツールチェインをインストールし、グローバルに設定する
# @latest を指定すると最新の安定版をインストールする
tools=(
	python@latest
	neovim@latest
	tmux@latest
	node@latest
	jq@latest
	fzf@latest
	fd@latest
	ripgrep@latest
	# redis-cli@latest
	# zig@latest
	# zls@latest
)

# インストール済みのツールは飛ばす（更新したいときは mise_upgrade を使う）
installed=$(mise ls --global --installed 2>/dev/null | awk '{print $1}') || true

targets=()
for tool in "${tools[@]}"; do
	if ! echo "$installed" | grep -qx "${tool%@*}"; then
		targets+=("$tool")
	fi
done

if [ ${#targets[@]} -ne 0 ]; then
	mise use --global --yes "${targets[@]}"
fi

# mycli は mise の python の pip で導入する
if ! mise exec -- python -m pip show mycli >/dev/null 2>&1; then
	mise exec -- python -m pip install --quiet mycli
fi
mise reshim

cd $HOME/setup

# bash
if [ -f $HOME/.bashrc ]; then
	rm $HOME/.bashrc
fi
cp -rfp ./.bashrc $HOME/

# tmux
if [ -f $HOME/.tmux.conf ]; then
	rm $HOME/.tmux.conf
fi
cp -rfp ./.tmux.conf $HOME/

# Neovim
mkdir -p $HOME/.config
if [ -f $HOME/.config/nvim ]; then
	rm -rf $HOME/.config/nvim
fi
cp -rf ./nvim $HOME/.config/

# vim-plug
if [ ! -e "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/autoload/plug.vim" ]; then
	sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
fi

# git
if [ ! -e "$HOME/.config/git/git-completion.bash" ]; then
	mkdir -p $HOME/.config/git
	curl -sS "https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash" -o "$HOME/.config/git/git-completion.bash"
fi
git config --global commit.template ~/setup/.gitmessages
git config --global alias.pushf 'push --force-with-lease --force-if-includes'
git config --global alias.unstage 'restore --staged :/'
git config --global --add --bool push.autoSetupRemote true
git config --global mergetool.keepBackup false

# git diff-highlight
if ! command -v diff-highlight >/dev/null; then
	if [ -e /usr/share/doc/git/contrib/diff-highlight/diff-highlight ]; then
		mkdir -p $HOME/.local/bin
		sudo cp /usr/share/doc/git/contrib/diff-highlight/diff-highlight $HOME/.local/bin/diff-highlight
		sudo chmod +x $HOME/.local/bin/diff-highlight

		git config --global pager.log "diff-highlight | less"
		git config --global pager.show "diff-highlight | less"
		git config --global pager.diff "diff-highlight | less"
	fi
fi

echo "DONE"
