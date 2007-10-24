PATH=$HOME/bin:/home/y/bin:/sbin:/bin:/usr/sbin:/usr/bin:/usr/games:/usr/local/sbin:/usr/local/bin:/usr/X11R6/bin; export PATH

# some more ls aliases
alias ll='ls -alrtF'
alias la='ls -A'
alias l='less'
alias rm='rm -i'
alias mv='mv -i'
alias cp='cp -i'

# If running interactively, then:
if [ "$PS1" ]; then

    # check the window size after each command and, if necessary,
    # update the values of LINES and COLUMNS.
    #shopt -s checkwinsize

    # enable color support of ls and also add handy aliases
    if [ "$TERM" != "dumb" ]; then
	case $OSTYPE in
	    linux*)
		eval `dircolors -b`
		alias ls='ls --color=auto';;
	    freebsd*)
		alias ls='ls -G'
		export LC_CTYPE=en_US.ISO8859-1;;
	esac
    fi



    # set a fancy prompt
    PS1='\u@\h:\w\$ '

    # If this is an xterm set the title to user@host:dir
    case $TERM in
	xterm*)
	    PROMPT_COMMAND='echo -ne "\033]2;${PWD}\007"'
	    ;;
	rxvt*)
	    PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD}\007"'
	    ;;
	*)
	    ;;
    esac

    # enable programmable completion features (you don't need to enable
    # this, if it's already enabled in /etc/bash.bashrc).
    #if [ -f /etc/bash_completion ]; then
    #  . /etc/bash_completion
    #fi

    if [ -d /home/y ]; then
	export CVS_RSH=yssh;
    fi
fi
