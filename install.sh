#!/usr/bin/env bash

set -eu

require_command() {
  local command=$1

  if ! command -v $command >/dev/null; then
    echo "$command is not install."
    exit 1
  fi
}

install_asdf() {
  cd $HOME &&
  ([ -e "$HOME/.asdf" ] || git clone https://github.com/asdf-vm/asdf.git .asdf)
}

install_asdf_plugin(){
  local name=$1
  local version=$2
  local url=$3

  local installed_version
  installed_version=$(asdf current "$name" 2>/dev/null | awk '{print $2}')
  if [ -z "$installed_version" ]; then
    asdf plugin add "$name" "$url"
    asdf install "$name" "$version"
    asdf global "$name" "$version"
  elif test "$installed_version" != "$version"; then
    asdf plugin update "$name"
    asdf install "$name" "$version"
    asdf global "$name" "$version"
  else
     return
  fi
}

# for install ASDF
require_command git
require_command curl
require_command gcc
# for install tmux
require_command make
require_command unzip

if command -v asdf >/dev/null; then
  . "$HOME/.asdf/asdf.sh"
  install_asdf_plugin nvim   latest https://github.com/richin13/asdf-neovim.git
  install_asdf_plugin tmux   latest https://github.com/aphecetche/asdf-tmux.git
  install_asdf_plugin node   latest https://github.com/asdf-vm/asdf-nodejs.git
  install_asdf_plugin jq     latest https://github.com/lsanwick/asdf-jq.git
  install_asdf_plugin fzf    latest https://github.com/kompiro/asdf-fzf.git
  install_asdf_plugin fd     latest https://gitlab.com/wt0f/asdf-fd.git
  echo "installed asdf plugin"
else
  install_asdf
  echo "installed asdf"
fi

cp ./.bashrc $HOME/
cp -r ./nvim $HOME/.config/
