#!/bin/bash

VERSION=0.3.1
WORKING_DIR=$(pwd)

# Find script dir and resolve symlinks

cd $(dirname $0)
cd $(dirname $(ls -l $0 | awk '{print $NF}'))
SCRIPT_DIR=$(pwd)
cd $WORKING_DIR

# Set docker images

COMPOSER_IMAGE="composer:latest"
JQ_IMAGE="stedolan/jq:latest"
NODE_IMAGE="node:8.7.0"

# Include cmd helpers

source $SCRIPT_DIR/cmd.sh

# Main Commands

ops-composer() {
    ops-docker run \
        --rm -itP \
        -v "$(pwd):/usr/src/app" \
        -w "/usr/src/app" \
        $COMPOSER_IMAGE \
        $@
}

ops-docker() {
    docker $@
}

ops-docker-compose() {
    docker-compose $@
}

ops-exec() {
    echo $@
    local service=$1
    shift

    local id=$(ops-docker-compose ps -q $service)

    [[ -z $id ]] && exit

    ops-docker exec -i $id $@
}

ops-jq() {
    ops-docker run --rm -i $JQ_IMAGE $@
}

ops-node() {
    ops-docker run \
        --rm -itP --init \
        -v "$(pwd):/usr/src/app" \
        -w "/usr/src/app" \
        $NODE_IMAGE \
        $@
}

ops-npm() {
    ops-docker run \
        --rm -itP --init \
        -v "$(pwd):/usr/src/app" \
        -w "/usr/src/app" \
        --entrypoint "npm" \
        $NODE_IMAGE \
        $@
}

ops-yarn() {
    ops-docker run \
        --rm -itP --init \
        -v "$(pwd):/usr/src/app" \
        -w "/usr/src/app" \
        --entrypoint "yarn"
        $NODE_IMAGE \
        $@
}

ops-start() {
    ops-docker-compose up -d
}

ops-stop() {
    ops-docker-compose stop
}

ops-logs() {
    ops-docker-compose logs -f
}

ops-ps() {
    ops-docker-compose ps
}

ops-shell() {
    local id=$(ops-docker-compose ps -q $1)
    shift

    [[ -z $id ]] && exit

    ops-docker exec -it $id $@
}

ops-stats() {
    local ids=$(ops-docker-compose ps -q)
    [[ -z $ids ]] && exit
    ops-docker stats $ids
}

ops-system() {
    cmd-run system $@
}

ops-help() {
    cmd-help ops ops
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
    cmd-help "ops system" system
    echo
}

# Run Main Command

main() {
    cmd-run ops $@
    exit
}

main $@
