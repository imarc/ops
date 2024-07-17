#!/usr/bin/env bash

RESTORE="$(tput sgr0)"
UNDERLINE="$(tput smul)"

RED="$(tput setaf 1)"
GREEN="$(tput setaf 2)"
YELLOW="$(tput setaf 3)"
BLUE="$(tput setaf 4)"
MAGENTA="$(tput setaf 5)"
CYAN="$(tput setaf 6)"
GRAY="$(tput setaf 7)"

LRED="$(tput bold)$RED"
LGREEN="$(tput bold)$GREEN"
LYELLOW="$(tput bold)$YELLOW"
LBLUE="$(tput bold)$BLUE"
LMAGENTA="$(tput bold)$MAGENTA"
LCYAN="$(tput bold)$CYAN"
WHITE="$(tput bold)$GRAY"

cmd-doc() {
    return;
}

cmd-alias() {
    return;
}

cmd-get-doc() {
    # callee
    # echo ${FUNCNAME[1]}

    local indent="${3-0}"
    local pad=""

    if [[ $indent > 0 ]]; then
        pad=$(seq -f " " -s "" $indent)
    fi

    declare -f $1 | \
        awk '/^[ \s]*cmd-doc /{print;}' | \
        sed -E 's/^ *cmd-doc +(.*);$/\1/' | \
        sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//" | \
        sed -e "s/^/$pad/"
}

cmd-help() {
    local name=$1
    local prefix=$2
    local commands=$(compgen -A function | awk "/--/{next;} /^$prefix-/{sub(\"$prefix-\",\"\"); print;}")
    local prefix_aliases=$(cmd-get-aliases ops-$prefix)
    local verbose=0

    echo
    echo "Usage: $name ${UNDERLINE}command${RESTORE}"
    if [[ -n "$prefix_aliases" ]]; then
        echo "Aliases: $prefix_aliases"
    fi
    echo
    echo "Available commands:"

    (
        local IFS=$'\n'
        for line in $commands
        do
            local aliases="$(cmd-get-aliases $prefix-$line)"
            if [[ -n "$aliases" ]]; then
                echo -e "  ${LGREEN}$line ($aliases)${RESTORE}\t$(cmd-get-doc $prefix-$line | head -n 1)"
            else
                echo -e "  ${LGREEN}$line${RESTORE}\t$(cmd-get-doc $prefix-$line | head -n 1)"
            fi
        done
    ) | column -t -s $'\t'

    echo
}

cmd-get-aliases() {
    declare -f $1 \ |
        awk '/^[ \s]*cmd-alias /{print;}' | \
        sed -E 's/^ *cmd-alias +(.*);$/\1/'
}

find-alias() {
    local prefix=$1
    local name=$2
    local commands=$(compgen -A function | awk "/--/{next;} /^$prefix-/{sub(\"$prefix-\",\"\"); print;}")

    local IFS=$'\n'
    for cmd in $commands
    do
        if [[ "$(cmd-get-aliases $prefix-$cmd)" == @(|* )"$name"@(| *) ]]; then
            echo $cmd
            exit
        fi
    done
}

cmd-run() {
    local prefix=$1
    local command="$2"
    shift
    shift

    if [[ -n $command ]]; then
        alias=$(find-alias $prefix $command)
        if [[ -n $alias ]]; then
            command=$alias
        fi
    fi

    [[ $(type -t $prefix-help) != 'function' ]]
    local has_help=$?

    [[ $(type -t $prefix-$command) != 'function' ]]
    local has_command=$?

    [[ $(type -t _$prefix-$command) != 'function' ]]
    local has_hidden_command=$?

    if [[ $has_help == 0 ]]; then
        eval "$prefix-help() { \
            cmd-doc 'Show ops help.'; \
            cmd-help '$prefix' '$prefix' \"\$@\"; \
        }"
    fi

    if [[ ( -z "$command" || $has_hidden_command == 0 && $has_command == 0 ) ]]; then
        command='help'
    fi

    [[ $(type -t $prefix-$command--before) != 'function' ]]
    local has_before_command=$?

    [[ $(type -t $prefix-$command--after) != 'function' ]]
    local has_after_command=$?

    if [[ $has_before_command != 0 ]]; then
        $prefix-$command--before "$@"
    fi

    if [[ $has_hidden_command != 0 ]]; then
        _$prefix-$command "$@"
        return
    else
        $prefix-$command "$@"
    fi

    if [[ $has_after_command != 0 ]]; then
        $prefix-$command--after "$@"
    fi
}

cmd-www() {
    echo "Opening $1..."
    if [ -n "$OPS_BROWSER" ]; then
        $OPS_BROWSER $1
    else
        case $OS in
            linux)
                xdg-open $1
                ;;
            mac)
                open $1
                ;;
            linux-wsl)
                explorer.exe $1
                ;;
        esac
    fi
}
