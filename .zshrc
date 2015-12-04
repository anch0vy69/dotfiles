
#          _              
#  _______| |__  _ __ ___ 
# |_  / __| '_ \| '__/ __|
#  / /\__ \ | | | | | (__ 
# /___|___/_| |_|_|  \___|
#                         
#

umask 022
limit coredumpsize 0
bindkey -d

# NOTE: set fpath before compinit
fpath=(~/.zsh/Completion(N-/) $fpath)
fpath=(~/.zsh/functions/*(N-/) $fpath)
fpath=(~/.zsh/plugins/zsh-completions(N-/) $fpath)
fpath=(/usr/local/share/zsh/site-functions(N-/) $fpath)

# autoload
autoload -U  run-help
autoload -Uz add-zsh-hook
autoload -Uz cdr
autoload -Uz colors; colors
autoload -Uz compinit; compinit -u
autoload -Uz is-at-least
autoload -Uz history-search-end
autoload -Uz modify-current-argument
autoload -Uz smart-insert-last-word
autoload -Uz terminfo
autoload -Uz vcs_info
autoload -Uz zcalc
autoload -Uz zmv
autoload     run-help-git
autoload     run-help-svk
autoload     run-help-svn

# It is necessary for the setting of DOTPATH
if [[ -f ~/.path ]]; then
    source ~/.path
else
    export DOTPATH="${0:A:t}"
fi

# DOTPATH environment variable specifies the location of dotfiles.
# On Unix, the value is a colon-separated string. On Windows,
# it is not yet supported.
# DOTPATH must be set to run make init, make test and shell script library
# outside the standard dotfiles tree.
if [[ -z $DOTPATH ]]; then
    echo "$fg[red]cannot start ZSH, \$DOTPATH not set$reset_color" 1>&2
    return 1
fi

# Vital
# vital.sh script is most important file in this dotfiles.
# This is because it is used as installation of dotfiles chiefly and as shell
# script library vital.sh that provides most basic and important functions.
# As a matter of fact, vital.sh is a symbolic link to install, and this script
# change its behavior depending on the way to have been called.
export VITAL_PATH="$DOTPATH/etc/lib/vital.sh"
if [[ -f $VITAL_PATH ]]; then
    source "$VITAL_PATH"
fi

antigen=~/.antigen
antigen_plugins=(
#"b4b4r07/cli-finder"
"b4b4r07/emoji-cli"
"b4b4r07/enhancd"
"b4b4r07/tmuxlogger"
"b4b4r07/zsh-gomi"
"b4b4r07/ssh-keyreg"
"b4b4r07/zsh-vimode-visual"
"brew"
"hchbaw/opp.zsh"
"zsh-users/zsh-completions"
"zsh-users/zsh-history-substring-search"
"zsh-users/zsh-syntax-highlighting"
)

setup_bundles() {
    echo -e "$fg[blue]Starting $SHELL....$reset_color\n"

    modules() {
        e_arrow $(e_header "Setup modules...")

        local -a modules_path
        modules_path=(
        ~/.zsh/[0-9]*.(sh|zsh)(N^*)
        ~/.modules/*.(sh|zsh)(N^*)
        )

        local f
        for f ($modules_path) source "$f" && echo "loading $f" | e_indent 2
    }

    # has_plugin returns true if $1 plugin are installed and available
    has_plugin() {
        #(( ${antigen_plugins[(I)$1]} ))
        (( ${antigen_plugins[(I)${${(M)1:#*/*}:-"*"/${1#*/}}|${1#*/}]} ))
        return $status
    }

    # bundle_install installs antigen and runs bundles command
    bundle_install() {
        # install antigen
        git clone https://github.com/zsh-users/antigen $antigen
        # run bundles
        bundles
    }

    # bundles checks if antigen plugins are valid and available
    bundles() {
        if [[ -f $antigen/antigen.zsh ]]; then
            e_arrow $(e_header "Setup antigen...")
            source $antigen/antigen.zsh

            # check plugins installed by antigen
            local p
            for p in ${antigen_plugins[@]}
            do
                echo "checking... $p" | e_indent 2
                antigen-bundle "$p"
            done

            # apply antigen
            antigen-apply
        else
            has "git" && echo "$fg[red]To make your shell strong, run 'bundle_install'.$reset_color"
        fi
    }

    bundles; echo
    modules; echo
}

zsh_startup() {
    # Exit if called from vim
    [[ -n "$VIMRUNTIME" ]] && return

    # Check whether the vital file is loaded
    if ! vitalize 2>/dev/null; then
        echo "$fg[red]cannot vitalize$reset_color" 1>&2
        return 1
    fi

    # tmux_automatically_attach attachs tmux session automatically when your are in zsh
    $DOTPATH/bin/tmuxx

    # setup_bundles return true if antigen plugins and some modules are valid
    setup_bundles || return 1

    # Display Zsh version and display number
    echo -e "\n$fg_bold[cyan]This is ZSH $fg_bold[red]${ZSH_VERSION}$fg_bold[cyan] - DISPLAY on $fg_bold[red]$DISPLAY$reset_color\n"
}

if zsh_startup; then
    # Important
    zstyle ':completion:*:default' menu select=2

    # Completing Groping
    zstyle ':completion:*:options' description 'yes'
    zstyle ':completion:*:descriptions' format '%F{yellow}Completing %B%d%b%f'
    zstyle ':completion:*' group-name ''

    # Completing misc
    zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
    zstyle ':completion:*' verbose yes
    zstyle ':completion:*' completer _expand _complete _match _prefix _approximate _list _history
    zstyle ':completion:*:*files' ignored-patterns '*?.o' '*?~' '*\#'
    zstyle ':completion:*' use-cache true
    zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters

    # Directory
    zstyle ':completion:*:cd:*' ignore-parents parent pwd
    export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'
    zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

    # default: --
    zstyle ':completion:*' list-separator '-->'
    zstyle ':completion:*:manuals' separate-sections true

    # Menu select
    zmodload -i zsh/complist
    bindkey -M menuselect '^h' vi-backward-char
    bindkey -M menuselect '^j' vi-down-line-or-history
    bindkey -M menuselect '^k' vi-up-line-or-history
    bindkey -M menuselect '^l' vi-forward-char
    #bindkey -M menuselect '^k' accept-and-infer-next-history
fi

# vim:fdm=marker fdc=3 ft=zsh ts=4 sw=4 sts=4:
