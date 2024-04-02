HISTSIZE=1000
HISTFILESIZE=2000
HISTCONTROL=ignoredups:ignorespace

PS1="\u@\h \D{%F %T} \w \$ "

alias bashrc='vim $HOME/.bashrc; source $HOME/.bashrc'

# ASDF
. "$HOME/.asdf/asdf.sh"
. "$HOME/.asdf/completions/asdf.bash"
