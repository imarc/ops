#!/usr/bin/env bash

RESTORE='\033[0m'

RED='\033[00;31m'
GREEN='\033[00;32m'
YELLOW='\033[00;33m'
BLUE='\033[00;34m'
PURPLE='\033[00;35m'
CYAN='\033[00;36m'
LIGHTGRAY='\033[00;37m'

LRED='\033[01;31m'
LGREEN='\033[01;32m'
LYELLOW='\033[01;33m'
LBLUE='\033[01;34m'
LPURPLE='\033[01;35m'
LCYAN='\033[01;36m'
WHITE='\033[01;37m'

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
    echo "Usage: $name <command>"
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
                echo -e "  ${GREEN}$line ($aliases)${RESTORE}\t$(cmd-get-doc $prefix-$line | head -n 1)"
            else
                echo -e "  ${GREEN}$line${RESTORE}\t$(cmd-get-doc $prefix-$line | head -n 1)"
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
            cmd-doc 'Show help'; \
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
