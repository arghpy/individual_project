# Options
setopt autocd              # change directory just by typing its name
setopt interactivecomments # allow comments in interactive mode

# Enable colors and change prompt:
autoload -U colors && colors	# Load colors
PS1="%B%{$fg[red]%}[%{$fg[yellow]%}%n%{$fg[green]%}@%{$fg[blue]%}%M %{$fg[magenta]%}%~%{$fg[red]%}]%{$reset_color%}$%b "


# enable completion features
autoload -Uz compinit
compinit -d ~/.cache/zcompdump
_comp_options+=(globdots)
zstyle ':completion:*:*:*:*:*' menu select


# History in cache directory:
HISTFILE=~/.zsh_history
HISTSIZE=10000000
SAVEHIST=10000000

#Syntax highlighting
if [ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    . /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

#Aliases
alias ls='ls --color=auto'
alias ll='ls -l --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'

alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias diff='diff --color=auto'
alias ip='ip --color=auto'

# enable auto-suggestions based on the history
if [ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    . /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# enable command-not-found if installed
if [ -f /etc/zsh_command_not_found ]; then
    . /etc/zsh_command_not_found
fi


########### Personal addition ##############


## Adding to path
export PATH=$PATH:/home/arghpy/.local/bin:/home/arghpy/.local/bin/dwm_scripts:/home/arghpy/.local/bin/dwmblocks_scripts

## Autostart x

if [ -z $DISPLAY ]; then
        exec startx
fi


source /home/arghpy/.profile

GTK_THEME=Adwaita:dark
