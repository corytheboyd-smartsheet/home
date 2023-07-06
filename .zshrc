# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


# ######################
# MY CONFIGURATION START
# ######################

export EDITOR=$(which vim)

function be() {
    bundle exec "$@"
}

function dgaf() {
    git reset && \
    git checkout . && \
    git clean -df
}

function pick_branch_fzf() {
  git branch \
      --color \
      --list \
      --format="%(color:dim green)%(objectname:short) %(color:bold white)%(refname:short) %(color:italic red)%(subject) %(color:bold white)%(committerdate)" \
      --sort -committerdate \
    | \
    fzf --ansi \
    | \
    awk '{ print $2 }'
}

function grhu() {
    git reset --hard origin/$(git_current_branch)
}

function pem_file_to_base64() {
  awk -v ORS='\\n' '1' "$1" | base64
}

function gbb() {
    git checkout $(pick_branch_fzf)
}

function routes() {
    bin/rails routes | fzf
}

function r() {
    bin/rails "$@"
}

# git interactive keep
function gik() {
    git add -p
    git checkout .
    git reset
}

# list merged feature branches (ex: `cb/feature-branch`)
function git_merged_feature_branches() {
    git fetch --all -p >/dev/null
    git branch -vv | \
        grep ': gone]' |  \
        grep --invert-match "\*" | \
        awk '{ print $1; }' | \
        grep --color=never -E "^(?:[a-zA-Z0-9_-]+\/)(?:[a-zA-Z0-9_-]+\/?)+"
}

# delete all merged feature branches
function git_delete_merged_feature_branches() {
    for branch in $(git_merged_feature_branches) ; do
        echo "Deleting branch: $branch"
        git branch -D "$branch"
    done
}

function git_change_base_branch() {
    function usage() {
        echo "Usage: git_change_base_branch NEW_BASE OLD_BASE\n\tNEW_BASE branch to rebase onto\n\tOLD_BASE previous base branch"
    }
    new_base="$1"
    old_base="$2"
    if [ -z "$new_base" ]; then
        usage
        return;
    fi
    if [ -z "$old_base" ]; then
        usage
        return;
    fi
    git rebase --onto "$new_base" "$old_base" $(git_current_branch)
}

function dcp() {
    docker compose "$@"
}

# ######################
# MY CONFIGURATION END
# ######################


# ##########################
# BRANDFOLDER CONFIG START
# ##########################

BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
LIME_YELLOW=$(tput setaf 190)
POWDER_BLUE=$(tput setaf 153)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
BRIGHT=$(tput bold)
NORMAL=$(tput sgr0)
BLINK=$(tput blink)
REVERSE=$(tput smso)
UNDERLINE=$(tput smul)

function info() {
    >&2 echo "${CYAN}$1${NORMAL}"
}

function warn() {
    >&2 echo "${YELLOW}$1${NORMAL}"
}

function error() {
     >&2 echo "${RED}$1${NORMAL}"
}

function confirm() {
    echo "$1"
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) return 0;;
            No ) return 1;;
        esac
    done
}

function gke_proxy() {
    if [ -z "$port"  ]; then
        error "must specify port env var, ex: port=9443 gke_proxy"
        return
    fi
    running_gke_proxy_port="$(lsof -ti:$port)" 
    if [ -n "$running_gke_proxy_port" ]; then
        warn "gke_proxy already running. pid=$running_gke_proxy_port"
        return
    fi
    (
        cd ~/code/terraform/squads/platform/bf-shared-gke/scripts
        ./start-gke-proxy.sh "$@"
    )
}

function gke_proxy_stage() {
    export port=9443
    gke_proxy stage -p "$port"
}

function gke_proxy_prod() {
    export port=9444
    gke_proxy prod -p "$port"
}

function gke_proxy_prod_us_central_1() {
    export port=9445
    gke_proxy prod -c us-c1-1
}

function k9s_stage() {
    port=9443
    if [ -z "$(lsof -i:$port)" ]; then
        error "proxy not running, start it with: kp"
        return
    fi
    HTTPS_PROXY="localhost:$port" k9s
}

function k9s_prod() {
    port=9444
    if [ -z "$(lsof -i:$port)" ]; then
        error "proxy not running, start it with: kpp"
        return
    fi
    HTTPS_PROXY="localhost:$port" k9s
}

function k9s_prod_us_central_1() {
    port=9445
    if [ -z "$(lsof -i:$port)" ]; then
        error "proxy not running, start it with: kppc"
        return
    fi
    HTTPS_PROXY="localhost:$port" k9s
}

function gke_run_sh_stage() {
    (
        cd ~/code/docker-images/bf-shared-gke-shell
        ./gke-run.sh stage boulder-web "$@"
    )
}

function gke_run_sh_prod() {
    (
        cd ~/code/docker-images/bf-shared-gke-shell
        ENV=prod ./gke-run.sh prod boulder-web "$@"
    )
}

function gke_run_sh_prod_ucs_central_1() {
    (
        cd ~/code/docker-images/bf-shared-gke-shell
        ENV=prod ./gke-run.sh prod boulder-web "$@"
    )
}

function dank_textify() {
    awk '{
        res="";
        split($0,a,//);
        for(i = 0; i < length(a); i++) {
            c=tolower(a[i+1]);
            if(match(c,/[a-z]/)) {
                res = res ":alphabet-white-" c ":"
            } else {
                res = res c
            }
        }
        print res
    }'
}

# ##########################
# BRANDFOLDER CONFIG END
# ##########################

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Load rbenv automatically by appending
# the following to ~/.zshrc:
eval "$(rbenv init - zsh)"

export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

# GCP CLI
source "$(brew --prefix)/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc"
source "$(brew --prefix)/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc"

# itermicil https://github.com/TomAnthony/itermocil#zsh-autocompletion
compctl -g '~/.itermocil/*(:t:r)' itermocil

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"

# Add gvm path
export GVM_ROOT="$HOME/.gvm"
[[ -s "/Users/cboyd/.gvm/scripts/gvm" ]] && source "/Users/cboyd/.gvm/scripts/gvm"

# brew postgresql@13
export PATH="/opt/homebrew/opt/postgresql@13/bin:$PATH"

source <(copilot completion zsh)
copilot completion zsh > "${fpath[1]}/_copilot" # to autoload on startup
