#!/bin/bash

OPS_VERSION=0.3.1

# Determine OS

OS=""
case "$(uname -s)" in
    Linux*)
        if $(grep -q Microsoft /proc/version); then
            OS="linux-wsl"
        else
            OS="linux"
        fi
        ;;
    Darwin*)
        OS="mac"
        ;;
esac

if [[ -z "$OS" ]]; then
    echo "Upsupported OS. Use Macintosh, Linux, or WSL"
    exit 1
fi

# Find script dir (and resolve symlinks)

OPS_WORKING_DIR=$(pwd)
cd $(dirname $0)
cd $(dirname $(ls -l $0 | awk '{print $NF}'))
OPS_SCRIPT_DIR=$(pwd)
cd $OPS_WORKING_DIR

# Include cmd helpers

source $OPS_SCRIPT_DIR/cmd.sh

# Config

OPS_HOME=${OPS_HOME-"$HOME/.ops"}
OPS_DOCKER_UTILS_IMAGE="ops-utils:$OPS_VERSION"

if [[ -f "$OPS_HOME/config" ]]; then
    source $OPS_HOME/config
fi

# Internal helpers

validate-config() {
    errors=()

    if [[ ! -d $OPS_HOME ]]; then
        echo "Ops not installed. Please run: ops system install"
        exit 1
    fi

    if [[ -z $OPS_SITES_DIR ]]; then
        errors+=("OPS_SITES_DIR config is not set")
    fi

    if [[ -z $OPS_DOMAIN ]]; then
        errors+=("OPS_DOMAIN config is not set")
    fi

    if [[ -n $errors ]]; then
        echo "The following items need to be addressed:"
        echo
        printf "%s\n" "${errors}"
        exit 1
    fi
}

# Main Commands

ops-composer() {
    local useropt=""
    if [[ "$OS" == 'linux' ]]; then
        local useropt="--user \"$OPS_DOCKER_UID:$OPS_DOCKER_GID\""
    fi

    ops-docker run \
        --rm -itP \
        -v "$(pwd):/usr/src/app" \
        -e "/usr/src/app" \
        -w "/usr/src/app" \
        $OPS_DOCKER_COMPOSER_IMAGE \
        composer $@
}

ops-docker() {
    docker $@
}

ops-exec() {
    echo $@
    local service=$1
    shift

    local id=$(system-docker-compose ps -q $service)

    [[ -z $id ]] && exit

    ops-docker exec -i $id $@
}

ops-help() {
    cmd-help ops ops
    echo $(ops-version)
    echo
}

ops-logs() {
    system-docker-compose logs -f $@
}

ops-mc() {
    ops-docker run \
        --rm -it \
        --network "ops_backend" \
        -v "$OPS_HOME/minio:/root/.mc" \
        -v "$OPS_SITES_DIR:/var/www/html" \
        -w "/var/www/html" \
        --entrypoint "mc" \
        minio/mc \
        $@
}

ops-mysql() {
    system-shell-exec mariadb mysql $@
}

ops-node() {
    ops-docker run \
        --rm -itP --init \
        -v "$(pwd):/usr/src/app" \
        -w "/usr/src/app" \
        --user "node" \
        ops-node:$OPS_VERSION \
        $@
}

ops-npm() {
    ops-docker run \
        --rm -itP --init \
        -v "$(pwd):/usr/src/app" \
        -w "/usr/src/app" \
        --user "node" \
        --entrypoint "npm" \
        ops-node:$OPS_VERSION \
        $@
}

ops-ps() {
    system-docker-compose ps $@
}

ops-psql() {
    system-shell-exec postgres psql $@
}

ops-gulp() {
    ops-docker run \
        --rm -itP --init \
        -v "$(pwd):/usr/src/app" \
        -w "/usr/src/app" \
        --user "node" \
        --entrypoint "gulp" \
        ops-node:$OPS_VERSION \
        $@
}

ops-redis() {
    system-shell-exec redis redis-cli $@
}

ops-restart() {
    system-docker-compose restart
}

ops-shell() {
    system-shell-exec $OPS_SHELL_SERVICE $OPS_SHELL_COMMAND
}

ops-site() {
    cmd-run site $@
}

ops-stats() {
    local ids=$(system-docker-compose ps -q)
    [[ -z $ids ]] && exit
    ops-docker stats $ids
}

ops-start() {
    validate-config
    system-docker-compose up -d
}

ops-stop() {
    system-docker-compose stop
}

ops-system() {
    cmd-run system $@
}

ops-version() {
    echo "ops version $OPS_VERSION"
}

ops-yarn() {
    ops-docker run \
        --rm -itP --init \
        -v "$(pwd):/usr/src/app" \
        -w "/usr/src/app" \
        --user "node" \
        --entrypoint "yarn" \
        ops-node:$OPS_VERSION \
        $@
}

# Site sub sommands

site-docker-compose() {
    docker-compose $@
}

site-start() {
    site-docker-compose up -d
}

site-stop() {
    site-docker-compose stop
}

site-logs() {
    site-docker-compose logs -f $@
}

site-ps() {
    site-docker-compose ps $@
}

site-exec() {
    echo $@
    local service=$1
    shift

    local id=$(site-docker-compose ps -q $service)

    [[ -z $id ]] && exit

    ops-docker exec -i $id $@
}

site-help() {
    cmd-help "ops site" site
    echo
}

site-shell-exec() {
    local id=$(site-docker-compose ps -q $1)
    shift

    [[ -z $id ]] && exit

    ops-docker exec -it $id $@
}

site-stats() {
    local ids=$(site-docker-compose ps -q)
    [[ -z $ids ]] && exit

    ops-docker stats $ids
}

# System Sub-Commands

system-docker-compose() {
    COMPOSE_PROJECT_NAME=ops \
    COMPOSE_FILE=$OPS_HOME/docker-compose.system.yml \
    OPS_DOMAIN=$OPS_DOMAIN \
    OPS_HOME=$OPS_HOME \
    OPS_SITES_DIR=$OPS_SITES_DIR \
    OPS_DOCKER_UID=$OPS_DOCKER_UID \
    OPS_DOCKER_GID=$OPS_DOCKER_GID \
    OPS_DOCKER_APACHE_IMAGE=$OPS_DOCKER_APACHE_IMAGE \
    OPS_MINIO_ACCESS_KEY=$OPS_MINIO_ACCESS_KEY \
    OPS_MINIO_SECRET_KEY=$OPS_MINIO_SECRET_KEY \
    docker-compose $@
}

system-shell-exec() {
    local service=$1
    local id=$(system-docker-compose ps -q $service)
    shift

    if [[ -z $id ]]; then
        echo "Service $service not available. Run: ops start"
        exit 1
    fi

    ops-docker exec -it $id $@
}

system-config() {
    local key=$1
    shift
    local val=$(local IFS=" "; echo "$@");

    if [[ -n $key && -n $val ]]; then
        sed -i"" -e "s/^$key=.*/$key=\"$val\"/" "$OPS_HOME/config"
    elif [[ -n $key ]]; then
        cat $OPS_HOME/config | awk "/^$1=(.*)/ { sub(/$1=/, \"\", \$0); print }"
    else
        cat $OPS_HOME/config
    fi
}

system-install() {
    # this needs to change
    # but for now just destroy the home directory
    rm -rf $OPS_HOME

    if [[ ! -d $OPS_HOME ]]; then
        cp -rp $OPS_SCRIPT_DIR/home $OPS_HOME
    fi

    source $OPS_HOME/config

    if [[ "$OS" == linux ]]; then
        local whoami="$(whoami)"

        system-config OPS_DOCKER_UID "$(id -u $whoami)"
        system-config OPS_DOCKER_GID "$(id -g $whoami)"
    fi

    source $OPS_HOME/config

    system-refresh
}

system-refresh() {
    #
    # Build config
    #

    sed "s/OPS_DOMAIN/$OPS_DOMAIN/" $OPS_HOME/dnsmasq/dnsmasq.conf.tmpl > $OPS_HOME/dnsmasq/dnsmasq.conf
    sed "s/OPS_DOMAIN/$OPS_DOMAIN/" $OPS_HOME/certs/ssl.conf.tmpl > $OPS_HOME/certs/ssl.conf

    sed \
        -e "s/OPS_MINIO_ACCESS_KEY/$OPS_MINIO_ACCESS_KEY/" \
        -e "s/OPS_MINIO_SECRET_KEY/$OPS_MINIO_SECRET_KEY/" \
        $OPS_HOME/minio/config.json.tmpl > $OPS_HOME/minio/config.json

    ops-docker build -t ops-node:$OPS_VERSION $OPS_HOME/node
    ops-docker build -t ops-utils:$OPS_VERSION $OPS_HOME/utils

    #
    # Clear out old cert
    #

    if [[ "$OS" == linux ]]; then

        # system certs
        sudo rm /usr/local/share/ca-certificates/ops-local-dev.crt 2>/dev/null
        sudo update-ca-certificates

        # chrome certs
        mkdir -p $HOME/.pki/nssdb
        certutil -d sql:$HOME/.pki/nssdb -D -n ops-local-dev 2>/dev/null

        # other certs
        # ???

    elif [[ "$OS" == mac ]]; then

        sudo security delete-certificate -c "ops-local-dev"

    fi

    #
    # Generate cert
    #

    ops-docker run --rm \
        -v $OPS_HOME:/ops-home \
        -i $OPS_DOCKER_UTILS_IMAGE \
        openssl genrsa -out /ops-home/certs/self-signed-cert.key 2048

    ops-docker run --rm \
        -v $OPS_HOME:/ops-home \
        -i $OPS_DOCKER_UTILS_IMAGE \
        openssl req -new -batch -passin pass: \
        -key /ops-home/certs/self-signed-cert.key \
        -out /ops-home/certs/self-signed-cert.csr \
        -config /ops-home/certs/ssl.conf

    ops-docker run --rm \
        -v $OPS_HOME:/ops-home \
        -i $OPS_DOCKER_UTILS_IMAGE \
        openssl x509 -req -sha256 -days 3650 \
        -in /ops-home/certs/self-signed-cert.csr \
        -signkey /ops-home/certs/self-signed-cert.key \
        -out /ops-home/certs/self-signed-cert.crt \
        -extensions v3_req \
        -extfile /ops-home/certs/ssl.conf

    #
    # Install Cert
    #

    if [[ "$OS" == linux ]]; then
        # system certs
        sudo cp $OPS_HOME/certs/self-signed-cert.crt /usr/local/share/ca-certificates/ops-local-dev.crt
        sudo update-ca-certificates

        # chrome certs
        certutil -d sql:$HOME/.pki/nssdb -A -t "P,," -n ops-local-dev -i $HOME/.ops/certs/self-signed-cert.crt

    elif [[ "$OS" == mac ]]; then

        sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain $OPS_HOME/certs/self-signed-cert.crt

    fi

    #
    # Regenerate/Restart services. (They might depend on the cert)
    #

    if [[ ! -z $(ops-ps | grep Up) ]]; then
        RUNNING=1
    fi

    system-docker-compose rm -fs

    if [[ ! -z $RUNNING ]]; then
        ops-start
    fi
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
