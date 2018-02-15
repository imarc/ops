#!/bin/bash

OPS_VERSION=0.3.0

# Find script dir and resolve symlinks

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done

SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

# Set docker images

COMPOSER_IMAGE="composer:latest"
JQ_IMAGE="stedolan/jq:latest"
NODE_IMAGE="node:8.7.0"

# Include cmd helpers

source $SCRIPT_DIR/cmd.sh

# Main Commands

ops-docker() {
    docker $@
}

ops-docker-compose() {
    docker-compose $@
}

ops-composer() {
    ops-docker run --rm \
        -it \
        -v "$(pwd):/usr/src/app" \
        -w "/usr/src/app" \
        $COMPOSER_IMAGE \
        $@
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
    ops-docker run --rm \
        -v "$(pwd):/usr/src/app" \
        -w "/usr/src/app" \
        -itP \
        --init \
        $NODE_IMAGE \
        $@
}

ops-npm() {
    ops-docker run --rm \
        -v "$(pwd):/usr/src/app" \
        -w "/usr/src/app" \
        -itP \
        --init \
        --entrypoint "npm" \
        $NODE_IMAGE \
        $@
}

ops-yarn() {
    ops-docker run --rm \
        -v "$(pwd):/usr/src/app" \
        -w "/usr/src/app" \
        -it \
        --init \
        --entrypoint "yarn" \
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
    local service=$1
    shift

    local id=$(ops-docker-compose ps -q $service)

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
