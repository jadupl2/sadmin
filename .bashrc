# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific aliases and functions
set -o vi
alias ls='ls --color'
alias rm='rm -i'
alias ll='ls -l'
alias grpe='grep'

# Color PS1
PS1='\[\033[1;33m\]\u\[\033[1;37m\]@\[\033[1;32m\]\h\[\033[1;37m\]:\w\[\033[1;36m\]\$ \[\033[0m\]'
# Normal PS1
PS1='\u@\h:\w $ '
export PS1

# Permit Group to modify
umask 0002

