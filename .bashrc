#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

# opencode
case ":$PATH:" in *":$HOME/.opencode/bin:"*) ;; *) export PATH="$HOME/.opencode/bin:$PATH" ;; esac

# >>> Codex installer >>>
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac
# <<< Codex installer <<<

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/home/harshil/google-cloud-sdk/path.bash.inc' ]; then . '/home/harshil/google-cloud-sdk/path.bash.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/home/harshil/google-cloud-sdk/completion.bash.inc' ]; then . '/home/harshil/google-cloud-sdk/completion.bash.inc'; fi

# Dotfiles repo (see ~/.dotfiles)
alias dots='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
