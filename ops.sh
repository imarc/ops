#!/bin/bash

OPS_VERSION=0.1.0

COMPOSER_IMAGE="composer:latest"
JQ_IMAGE="stedolan/jq:latest"
NODE_IMAGE="node:8.7.0"

# Helpers

show-help() {
    local name=$1
    local prefix=$2
    local commands=$(compgen -A function | awk "/^$prefix-/{sub(\"$prefix-\",\"\"); print}")

    echo
    echo "Usage: $name <command>"
    echo
    echo "where <command> is one of:"

    local IFS=$'\n'
    for line in $(echo $commands | awk NF=NF RS= OFS=", " | fold -w 56 -s);
    do
        echo "    $line"
    done

    echo
}

parse-command() {
    local prefix=$1
    local command="$2"
    shift

    [[ $(type -t $prefix-help) != 'function' ]]
    local has_help=$?

    [[ $(type -t $prefix-$command) != 'function' ]]
    local has_command=$?

    if [[ ( -z "$command" || $has_command == 0 ) && $has_help == 1 ]]; then
        $prefix-help
        exit
    fi

    $prefix-$command $@
}

# Main Commands

ops-docker() {
    docker $@
}

ops-docker-compose() {
    docker-compose $@
}

ops-composer() {
    ops-run \
        -it \
        -v "$(pwd):/usr/src/app" \
        -w "/usr/src/app" \
        $COMPOSER_IMAGE \
        $@
}

ops-jq() {
    ops-run -i $JQ_IMAGE $@
}

ops-node() {
    ops-run \
        -v "$(pwd):/usr/src/app" \
        -w "/usr/src/app" \
        -itP \
        --init \
        $NODE_IMAGE \
        $@
}

ops-npm() {
    ops-run \
        -v "$(pwd):/usr/src/app" \
        -w "/usr/src/app" \
        -itP \
        --init \
        --entrypoint "npm" \
        $NODE_IMAGE \
        $@
}

ops-yarn() {
    ops-run \
        -v "$(pwd):/usr/src/app" \
        -w "/usr/src/app" \
        -it \
        --init \
        --entrypoint "yarn" \
        $NODE_IMAGE \
        $@
}

ops-run() {
    docker run --rm $@
}

ops-start() {
    ops-docker-compose up -d
}

ops-stop() {
    ops-docker-compose stop
}

ops-system() {
    parse-command system $@
}

ops-help() {
    show-help ops ops
    echo $(ops-version)
    echo
}

ops-version() {
    echo "ops version $OPS_VERSION"
}


# System Sub-Commands

system-start() {
    echo 'tbd';
}

system-stop() {
    echo 'tbd';
}

system-help() {
    show-help "ops system" system
    echo
}

# Run Main Command

main() {
    parse-command ops $@
    exit
}

main $@
