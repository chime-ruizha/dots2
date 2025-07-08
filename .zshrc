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
AWS_CONFIG_FILE="aws-sso-config"
AWS_PROFILE=aws-ecr-imagepull
AWS_SHARED_CREDENTIALS_FILE="/dev/null"
PATH="$PATH:$HOME/.local/bin:$GOPATH/bin:$HOME/.scripts:$GOPATH:$GOPATH/bin:/opt/homebrew/bin:/usr/local/bin:$HOME/.config/gitcmds"
VISUAL=$EDITOR
export PYTHONPATH=$(which python3)

BUNDLE_GEM__FURY__IO=$GEMFURY_TOKEN

CIRCUIT_BREAKER_REDIS_URL=redis://localhost
CIRCUIT_BREAKER_STATES_REDIS_URL=redis://localhost
RAILS_ENV=test

export GOPRIVATE=github.com/1debit/*
export GITHUB_TOKEN=$GITHUB_TOKEN
export HOMEBREW_GITHUB_API_TOKEN=$GITHUB_TOKEN
export GOEXPERIMENT=rangefunc

plugins=(git)

source $ZSH/oh-my-zsh.sh

HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000000
SAVEHIST=10000000
export HISTTIMEFORMAT="%F %T "

REPO_ROOT="$HOME/repos"
APERTURE_ROOT="$REPO_ROOT/aperture"

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

function vv() {
	if [[ $1 == "" ]];
	then
		source .env/bin/activate
	else
		source $1/bin/activate
	fi
}

func unpack-caf() {
    unzip '*.CAF' -d unzipped
    for file in unzipped/*.CAF; do mv "$file" "${file/.CAF/.CAF.json}"; done
}

function pin() {
	if [[ ! -f $HOME/.pbklist ]]; then
		touch $HOME/.pbklist
	fi
	if [[ $1 == "" ]]; then
		echo "Please specify 'mark', 'rm', 'clearall', 'list', 'find', or a label"
	elif [[ $1 == "mark" || $1 == "mk" || $1 == "s" ]]; then
		pin rm $2 # delete entry if it already exists
		echo $2::$(pwd) >> $HOME/.pbklist
	elif [[ $1 == "rm" ]]; then
		for i in {2.."$#"}; do
			sed -i '' "/$@[i]::/d" $HOME/.pbklist
		done
	elif [[ $1 == "l" || $1 == "list" ]]; then
		cat $HOME/.pbklist
	elif [[ $1 == "clearall" ]]; then
		rm $HOME/.pbklist
		touch $HOME/.pbklist
	elif [[ $1 == "find" ]]; then
		grep -i "$2" $HOME/.pbklist
	else
		mkr=$(grep "$1::" $HOME/.pbklist)
		if [[ mkr == "" ]]; then
			echo "No bookmark $1 found"
		else
			cd ${mkr//$1:://}
		fi
	fi
}

function b64d() {
    echo "$1" | base64 --decode
}

function gen-aws-creds() {
    git clone https://github.com/1debit/security-scripts.git $HOME/repos/security-scripts
    cd $HOME/repos/security-scripts
    ./aws-scripts/generate-aws-sso-config.py
    echo "Now, follow the instructions the script prints out"
     
    # log in once a day. daily-login profile is used for initial login
    aws sso login --profile=daily-login
     
    # View PICK_A_PROFILE name choices:
    aws configure list-profiles
     
    # pick a profile (NOT daily-login)
    aws sts get-caller-identity --profile PICK_A_PROFILE
     
    # If the above command is empty or outdated, run the below, then try again
    # cp ~/Downloads/generated_sso_config ~/.aws/config
}

function ccert() {
    aws sso login --profile Okta-Administrator-110535878513
    aws sso login --profile aws-ecr-imagepull
}

function fptest() {
    arg=""
    testtype=""
    if [[ $1 == 'unit' ]]; then
        arg="-count=1"
        testtype="unit"
    elif [[ $1 == 'integration' ]]; then
        arg="--tag=integration"
        testtype="integration"
    else
        echo "fptest <unit|integration> (repos)"
        return
    fi
    if [[ $2 == 'all' ]]; then
        echo "\nRunning: go test $arg $HOME/repos/aperture/...\n"
        go test -v $arg $HOME/repos/aperture/...
    else
        for i in {2.."$#"}; do
            if [[ $@[i] == 'ours' ]]; then
                echo "=========Running $testtype test for: visagateway,cardtransaction========="
                echo "Running: go test $arg $HOME/repos/aperture/visagateway/... $HOME/repos/aperture/cardtransaction/...\n"
                go test $arg $HOME/repos/aperture/visagateway/... $HOME/repos/aperture/cardtransaction/...
            else
                echo "=========Running $testtype test for: $@[i]========="
                echo "Running: go test $arg $HOME/repos/aperture/$@[i]/...\n"
                go test -v $arg $HOME/repos/aperture/$@[i]/...
            fi
        done
    fi
}

func dev-up() {
    echo "Setting up non-prod env"
    cd ~/repos/aperture
    if make down && make down killvisagateway killfinplat killgalileogateway; then
        if make up; then
                rm auth.json
            if make authenticate_user_endtoendtest; then
                authtoken=$(cat auth.json | jq '.token?' | sed "s/\"//g")
                export E2E_ENV=nonprod
                export AUTH_E2E_TESTS_OKTA_TOKEN=$authtoken
                if make buildrunvisagateway buildrunfinplat buildrun-visa-dps-simulator buildrungalileogateway; then
                    echo "Non-prod setup completed"
                    echo "ENV:                       $E2E_ENV"
                    echo "AUTH_E2E_TESTS_OKTA_TOKEN: $AUTH_E2E_TESTS_OKTA_TOKEN"
                else
                    echo "Failed to run 'make buildrunvisagateway buildrunfinplat buildrun-visa-dps-simulator'"
                fi
            else
                echo "Failed to run 'make authenticate_user_endtoendtest'"
            fi
        else
            echo "Failed to run 'make up'"
        fi
    else
        echo "Failed to run 'make down'"
    fi
}

func dev-down() {
    make down && make down killvisagateway killfinplat
}

function sdot() {
	pin mark tmp_sdot

	cp $HOME/.zshrc $HOME/repos/dots/.zshrc
	cp $HOME/.tmux.conf $HOME/repos/dots/.tmux.conf
	cp $HOME/.vimrc $HOME/repos/dots/.vimrc
    cp -r $HOME/.scripts $HOME/repos/.scripts
    msg=""
    if [[ $1 != "" ]]; then
        msg=$1
    fi
	cd $HOME/repos/dots
	git add -A
	git commit -m "Updating dots $(date +%d.%m.%y-%H:%M:%S) [$msg]"
	git push origin main
	pin tmp_sdot
	pin rm tmp_sdot
}

function mkp() {
    for i in {1.."$#"}; do
        make $1
    done
}

function gitpp() {
    git pull --no-ff origin main
    git pull --no-ff
    git push -u origin $curb
}

function pp() {
    lsof -i tcp$1
}

function jsoncheck() {
    if jq -e . >/dev/null 2>&1 <<<$(cat $1); then
        echo "Parsed JSON successfully and got something other than false/null"
    else
        echo "Failed to parse JSON, or got false/null"
    fi
}

function initialize() {
    echo "You are being set up, please do not resist"
    echo "============================================================"
    echo "Installing compass..."
    brew install 1debit/chime/compass
}

function sdm-mgr() {
    if [[ $1 == 'prod' ]]; then
        kubectl config use-context eks-use1-fp-prod-b006
    elif [[ $1 == 'nonprod' ]]; then
        kubectl config use-context eks-use1-fp-nprod-b007
    elif [[ $1 == 'dev' ]]; then
        kubectl config use-context eks-use1-fp-dev-b009
    fi
    echo "Current k8s Context: $(kubectl config current-context)"
}

function pod() {
    if [[ $1 == '' ]]; then
        echo $LAST_POD
    elif [[ $1 == 'connect' ]]; then
        if [[ $3 == '--env' && $4 != '' ]]; then
            compass console run $2 --env $4
        else
            compass console run $2 --env prod
        fi
    elif [[ $1 == '--reconnect' ]]; then
        if [[ $LAST_POD == '' ]]; then
            echo 'Please set $LAST_POD'
        else
            kubectl -n finplat-prod-consoles attach -it $LAST_POD
        fi
    elif [[ $1 == 'set' ]]; then
        export LAST_POD=$2
    fi
}

function aperture-test() {
    if [[ $2 == '' ]]; then
        go test -count=1 -v $APERTURE_ROOT/$1
    else
        go test -count=1 -v $APERTURE_ROOT/$1 -run $2
    fi
}

function aperture-integration-test() {
    if [[ $2 == '' ]]; then
        go test -count=1 -v -tags=integration $APERTURE_ROOT/$1
    else
        go test -count=1 -v -tags=integration $APERTURE_ROOT/$1 -run $2
    fi
}

function uuid() {
    uuidgen | awk '{ print tolower($0) }'
}

function e2e() {
    if [[ $1 == "" ]]; then
        echo $E2E_ENV
    else
        export E2E_ENV=$1
        echo 'E2E_ENV='$E2E_ENV
    fi
}

function check-url-exists() {
    if curl --head --silent --fail $1 2> /dev/null;
     then
      echo "This page exists."
     else
      echo "This page does not exist."
    fi
}

func ddiff() {
    diff -u $@ | diff-so-fancy
}

func restart-visagateway() {
    make killvisagateway && make buildrunvisagateway
}

func sup() {
    duration='5m'
    workers='1'
    if [[ $2 != '' ]]; then
        duration=$2
    fi
    if [[ $3 != '' ]]; then
        workers=$3
    fi

    hey -z ${duration} -c ${workers} -m GET -H "Chime-Service-Identity: test-zero-downtime-deploy" $1 
}

func nn() {
    cl=$(pwd)
    cd $(git rev-parse --show-toplevel)
    fp=$(fzf)
    if [[ fp != '' ]]; then
	nvim $fp
    fi
    cd $cl
}

alias aperture="cd $APERTURE_ROOT"
alias chime-schemas="cd $HOME/repos/chime-schemas"
export TERM="xterm-256color"
alias tmux="TERM=screen-256color-bce tmux"
alias zz="source ~/.zshrc"
alias ze="vim ~/.zshrc && zz"
alias python="python3"
alias curb="git rev-parse --abbrev-ref HEAD"
alias fport="sudo lsof -i -P | grep LISTEN | grep"
alias dlv="$HOME/go/bin/dlv"
export AIRFLOW_HOME=$HOME/chime/data-airflow
alias finplat-cli=$HOME/repos/finplat-cli/bin/finplat-cli
alias update-schemas="go get -v -x github.com/1debit/chime-schemas@main"
alias ve="nvim $HOME/.config/nvim"
alias kubecfg="nvim $HOME/.kube/config"
alias ctc="$APERTURE_ROOT/script/compile_to_console.sh"
alias wip="git add -A; git commit -m \"WIP\" --no-verify"
alias uncommit="git reset HEAD^"
alias gitsha="git rev-parse HEAD"
alias history='history -f'
alias hxlang='hx ~/.config/helix/languages.toml'
alias hxconf='hx ~/.config/helix/config.toml'
alias vimconf='nvim ~/.config/nvim/init.vim'
alias pdlv='python $HOME/.scripts/delver.py'
alias migrate="$APERTURE_ROOT/bin/migrate"
alias trigger-ci="git commit --allow-empty -m \"Trigger CI\" && git push"

export WORK_DIR_PATH=$REPO_ROOT
export LOCAL_GEM_PATH=$WORK_DIR_PATH
export HOMEBREW_GITHUB_API_TOKEN=$GITHUB_TOKEN
export BUNDLE_GITHUB__COM="$GITHUB_TOKEN:x-oauth-basic"
export BUNDLE_CHIME__JFROG__IO="$ARTIFACTORY_READ_USER:$ARTIFACTORY_READ_TOKEN"
export ARTIFACTORY_NPM_AUTH=$(echo -n "$ARTIFACTORY_READ_USER:$ARTIFACTORY_READ_TOKEN" | base64)

func dynamoadmin() {
    DYNAMO_ENDPOINT=http://$1 dynamodb-admin -H localhost -p 8000
}

func pj() {
  if [[ $1 == "--persist" ]]; then
    cat $2 | jq > .ppjson.tmp
    if [[ $? -eq 0 ]]; then
      mv .ppjson.tmp $2
    else
      rm .ppjson.tmp
    fi
  else
    cat $1 | jq
  fi
}

func kc-start-job() {
    kubectl -n $1 create-job --from=$2 $3
    echo $3
}

if [ -d "/usr/local/opt/ruby/bin" ]; then
  export PATH=/usr/local/opt/ruby/bin:$PATH
  export PATH=`gem environment gemdir`/bin:$PATH
fi

func cs() {
    open "http://go/$1/$2"
}

func isodecode() {
    b64d $1 | jq
}

func decodeiso() {
    isodecode $1
}

func cb() {
    echo $1 | pbcopy
}

func dive() {
    dlv test --build-flags="--tags=integration,endtoendtest" $1 -- -test.run $2
}

func kc() {
    if [[ $1 == 'cp' ]]; then
        cluster=$2
        console=$3
        kubectl cp -n "finplat-${cluster}-consoles" $4 ${console}:/home
    else
        echo "cp [env] [kube pod] [binary]"
    fi
}

func k8s-cp() {
  kubectl cp -n finplat-prod-consoles $1 $2
}

func pbc() {
    cat $1 | pbcopy
}

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"

export AWS_REGION=us-east-1
export USER_SERVICE_AUTH_TOKEN=secret
export USER_SERVICE_URL=http://user-service
export AWS_LOCALSTACK_ENDPOINT=http://localstack
export FLIPPER_REDIS_URL=redis://localhost
export CIRCUIT_BREAKER_STATES_REDIS_URL=redis://redis
alias vim='nvim'
alias ve="nvim ~/.config/nvim/init.lua"
export CIRCUIT_BREAKER_REDIS_URL=redis://redis
alias kcp="kubectl -n finplat-prod"
alias luhn="python $HOME/luhn.py"
alias btop="bpytop"
alias mcr="git add -A && git commit -m \"resolved mc\" && git rebase --continue"
