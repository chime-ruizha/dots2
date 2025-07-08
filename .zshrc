export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="passion"

eval "$($(which brew) shellenv)"

ZSH_DISABLE_COMPFIX=true

source ~/.secrets
source ~/repos/aperture/.env
source ~/.cargo/env
# source ~/.gemfury

# avoid duplicates..
export HISTCONTROL=ignoredups:erasedups

# append history entries..
setopt APPEND_HISTORY

# After each command, save and reload history
export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"
export BROWSER="chrome"

export EDITOR="vim"

export GOPATH=$HOME/go
PATH="$PATH:$HOME/.local/bin:$GOPATH/bin:$HOME/.scripts:$GOPATH:$GOPATH/bin:/opt/homebrew/bin:/usr/local/bin:$HOME/.config/gitcmds"
VISUAL=$EDITOR
export PYTHONPATH=$(which python3)
plugins=(git)

source $ZSH/oh-my-zsh.sh

HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000000
SAVEHIST=10000000
export HISTTIMEFORMAT="%F %T "

func hgl() {
    PS3="branch: "
    select branch in $(git branch | grep $1); do
        if [[ $branch == 'exit' ]]; then
            break
        fi
        git checkout $branch
        break
    done
    COLUMNS=0
}

function b64d() {
    echo "$1" | base64 --decode
}
