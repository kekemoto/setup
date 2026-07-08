#!/usr/bin/env bash
set -eu

require_command() {
	local command=$1

	if ! command -v $command >/dev/null; then
		echo "$command is not install."
		exit 1
	fi
}

install_asdf_plugin() {
	local name=$1
	local version=$2
	local url=$3

	# プラグインを追加（未追加の場合のみ）
	if ! asdf plugin list 2>/dev/null | grep -qx "$name"; then
		asdf plugin add "$name" "$url"
	else
		asdf plugin update "$name"
	fi

	# バージョンが latest の場合は最新の安定版を取得
	local target_version="$version"
	if test "$version" = "latest"; then
		target_version=$(asdf latest "$name")
	fi

	local installed_version
	installed_version=$(asdf current "$name" 2>/dev/null | awk '{print $2}')
	if test "$installed_version" != "$target_version"; then
		asdf install "$name" "$target_version"
		asdf global "$name" "$target_version"
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

# for install asdf
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

# install asdf
if ! command -v asdf >/dev/null; then
	cd $HOME
	([ -e "$HOME/.asdf" ] || git clone https://github.com/asdf-vm/asdf.git --branch 'v0.15.0' .asdf)
	. "$HOME/.asdf/asdf.sh"
fi

# intall asdf plugin
. "$HOME/.asdf/asdf.sh"
# バージョンに latest を指定すると最新の安定版をインストールする
install_asdf_plugin python latest https://github.com/danhper/asdf-python.git
install_asdf_plugin nvim latest https://github.com/richin13/asdf-neovim.git
install_asdf_plugin tmux latest https://github.com/aphecetche/asdf-tmux.git
install_asdf_plugin node latest https://github.com/asdf-vm/asdf-nodejs.git
install_asdf_plugin jq latest https://github.com/lsanwick/asdf-jq.git
install_asdf_plugin fzf latest https://github.com/kompiro/asdf-fzf.git
install_asdf_plugin fd latest https://gitlab.com/wt0f/asdf-fd.git
install_asdf_plugin rg latest https://gitlab.com/wt0f/asdf-ripgrep.git
# install_asdf_plugin redis-cli latest https://github.com/NeoHsu/asdf-redis-cli.git
# install_asdf_plugin mysql     latest https://github.com/iroddis/asdf-mysql.git
# install_asdf_plugin zig       latest https://github.com/cheetah/asdf-zig.git
# install_asdf_plugin zls       latest https://github.com/m1ome/asdf-zls

if command -v pip >/dev/null; then
	if ! command -v mycli >/dev/null; then
		pip install -U mycli
	fi
else
	echo "mycli はインストールできませんでした（pip が見つからなかった）"
fi

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
