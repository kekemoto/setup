export HISTSIZE=1000
export HISTFILESIZE=10000
export HISTCONTROL=ignoredups:ignorespace

export PS1="\u@\h \D{%F %T} \w \$ "
export EDITOR=nvim

alias bashrc='. $HOME/.bashrc'

alias ls='ls -a'
alias ll='ls -al'

alias gs='git status'
alias ga='git add -A'
alias gc='git commit'
alias gl='git log'

# ASDF
. "$HOME/.asdf/asdf.sh"
. "$HOME/.asdf/completions/asdf.bash"
