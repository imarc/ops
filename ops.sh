#!/bin/bash

OPS_VERSION=0.4.2

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

_ops-composer() {
    mkdir -p "$HOME/.composer"
    mkdir -p "$HOME/.ssh"

    ops docker run \
        --rm -itP \
        -v "$(pwd):/usr/src/app" \
        -v "$OPS_HOME/composer:/composer" \
        -v "$HOME/.ssh:/var/www/.ssh" \
        -v "$ssh_agent:/ssh-agent" \
        -e "SSH_AUTH_SOCK=/ssh-agent" \
        -e "COMPOSER_HOME=/composer" \
        -w "/usr/src/app" \
        --label=ops.site="$(ops site id)" \
        --user "www-data:www-data" \
        $OPS_DOCKER_COMPOSER_IMAGE \
        composer -n "$@"
}

_ops-docker() {
    docker "$@"
}

ops-exec() {
    local service=$1
    shift

    local id=$(system-docker-compose ps -q $service)

    [[ -z $id ]] && exit

    ops docker exec -i $id "$@"
}

ops-help() {
    #cmd-help ops ops

    cat << 'EOD'
Usage: ops <command>

where <command> is one of:

exec            Run a command on a service
help            Display help
logs            Follow system logs
mariadb         Mariadb CLI
mariadb-import  Import MariaDB database
mariadb-export  Export MariaDB database
ps              View service status
psql            PostgreSQL CLI
psql-import     Import PostgreSQL database
psql-export     Export PostgreSQL database
restart         Restart services
shell           Bash prompt in Apache container
start           Start services
stats           View service stats (CPU, Mem, Net I/O)
stop            Stop services
version         Show Ops version

EOD

    echo $(ops-version)
    echo
}

ops-logs() {
    system-docker-compose logs -f "$@"
}

_ops-mc() {
    ops docker run \
        --rm -it \
        --network "ops_backend" \
        -v "$OPS_HOME/minio:/root/.mc" \
        -v "$OPS_SITES_DIR:/var/www/html" \
        -w "/var/www/html" \
        --entrypoint "mc" \
        minio/mc \
        "${@}"
}

ops-mariadb() {
    system-shell-exec mariadb mysql "${@}"
}

ops-mariadb-export() {
    local db="$1"

    ops-exec mariadb mysqldump --single-transaction "$db"
}

ops-mariadb-import() {
    local db="$1"
    local sqlfile="$2"

    ops-exec mariadb mysql -e "DROP DATABASE IF EXISTS $db"
    ops-exec mariadb mysql -e "CREATE DATABASE $db"

    cat "$sqlfile" | ops-exec mariadb mysql "$db"
}

_ops-node() {
    ops docker run \
        --rm -itP --init \
        -v "$(pwd):/usr/src/app" \
        -w "/usr/src/app" \
        --label=ops.site="$(ops site id)" \
        --user "node" \
        --entrypoint "node" \
        ops-node:$OPS_VERSION \
        "$@"
}

_ops-npm() {
    ops docker run \
        --rm -itP --init \
        -v "$(pwd):/usr/src/app" \
        -v "$HOME/.ssh:/home/node/.ssh" \
        -w "/usr/src/app" \
        --label=ops.site="$(ops site id)" \
        --user "node" \
        --entrypoint "npm" \
        ops-node:$OPS_VERSION \
        "$@"
}

ops-ps() {
    system-docker-compose ps "$@"
}

ops-psql() {
    system-shell-exec postgres psql -U postgres "$@"
}

ops-psql-export() {
    local db="$1"

    ops-exec postgres pg_dump -U postgres "$db"
}

ops-psql-import() {
    local db="$1"
    local sqlfile="$2"

    ops-psql -c "DROP DATABASE $db"
    ops-psql -c "CREATE DATABASE $db"

    cat "$sqlfile" | ops-exec postgres psql -U postgres "$db"
}

_ops-gulp() {
    ops docker run \
        --rm -itP --init \
        -v "$(pwd):/usr/src/app" \
        -w "/usr/src/app" \
        --label=ops.site="$(ops site id)" \
        --user "node" \
        --entrypoint "gulp" \
        ops-node:$OPS_VERSION \
        "$@"
}

ops-redis() {
    system-shell-exec redis redis-cli "$@"
}

ops-restart() {
    system-docker-compose restart
}

ops-shell() {
    #system-shell-exec $OPS_SHELL_SERVICE $OPS_SHELL_COMMAND

    ops docker run \
        --rm -itP \
        -v "$(pwd):/usr/src/app" \
        -v "$HOME/.ssh:/var/www/.ssh" \
        -e "COMPOSER_HOME=/composer" \
        -w "/usr/src/app" \
        --label=ops.site="$(ops site id)" \
        --user "www-data:www-data" \
        $OPS_DOCKER_APACHE_IMAGE \
        bash
}

ops-site() {
    cmd-run site "$@"
}

ops-stats() {
    local ids=$(system-docker-compose ps -q)
    [[ -z $ids ]] && exit
    ops docker stats $ids
}

ops-start() {
    validate-config
    system-start
}

ops-stop() {
    system-stop
}

_ops-yq() {
    ops docker run \
        --rm -i \
        -v "$(pwd):/usr/src/" \
        -w "/usr/src/" \
        $OPS_DOCKER_UTILS_IMAGE \
        yq \
        "$@"
}

_ops-jq() {
    ops docker run \
        --rm -i \
        -v "$(pwd):/usr/src/" \
        -w "/usr/src/" \
        $OPS_DOCKER_UTILS_IMAGE \
        jq \
        "$@"
}

ops-system() {
    cmd-run system "$@"
}

ops-version() {
    echo "ops version $OPS_VERSION"
}

_ops-yarn() {
    ops docker run \
        --rm -itP --init \
        -v "$(pwd):/usr/src/app" \
        -w "/usr/src/app" \
        --label=ops.site="$(ops site id)" \
        --user "node" \
        --entrypoint "yarn" \
        ops-node:$OPS_VERSION \
        "$@"
}

# Site sub sommands

site-docker-compose() {
    local compose_file="docker-compose.yml"
    if [[ -f "docker-compose.ops.yml" ]]; then
        compose_file+=":docker-compose.ops.yml"
    fi

    OPS_DOMAIN=$OPS_DOMAIN \
    OPS_SITE_BASENAME="$(basename $PWD)" \
    COMPOSE_PROJECT_NAME="ops$(basename $PWD)" \
    COMPOSE_FILE="$compose_file" \
    docker-compose "$@"
}

site-id() {
    local basename="$(basename $(pwd))"

    (
        while [[ "$(pwd)" != $OPS_SITES_DIR ]] && [[ "$(pwd)" != '/' ]]; do
            cd ..
            basename=$(basename $(pwd))
        done
    )

    if [[ -n "$basename" ]]; then
        echo $basename
    fi
}

site-start() {
    site-docker-compose up -d
}

site-stop() {
    site-docker-compose stop
}

site-logs() {
    site-docker-compose logs -f "$@"
}

site-ps() {
    site-docker-compose ps "$@"
}

site-exec() {
    local service=$1
    shift

    local id=$(site-docker-compose ps -q $service)

    [[ -z $id ]] && exit

    ops docker exec -i $id "$@"
}

site-help() {
    cmd-help "ops site" site
    echo
}

site-shell-exec() {
    local id=$(site-docker-compose ps -q $1)
    shift

    [[ -z $id ]] && exit

    ops docker exec -it $id "$@"
}

site-stats() {
    local ids=$(site-docker-compose ps -q)
    [[ -z $ids ]] && exit

    ops docker stats $ids
}

# System Sub-Commands

system-docker-compose() {
    COMPOSE_PROJECT_NAME="ops" \
    COMPOSE_FILE=$OPS_HOME/docker-compose.system.yml \
    OPS_DOMAIN=$OPS_DOMAIN \
    OPS_HOME=$OPS_HOME \
    OPS_SITES_DIR=$OPS_SITES_DIR \
    OPS_DOCKER_UID=$OPS_DOCKER_UID \
    OPS_DOCKER_GID=$OPS_DOCKER_GID \
    OPS_DOCKER_APACHE_IMAGE=$OPS_DOCKER_APACHE_IMAGE \
    OPS_MINIO_ACCESS_KEY=$OPS_MINIO_ACCESS_KEY \
    OPS_MINIO_SECRET_KEY=$OPS_MINIO_SECRET_KEY \
    docker-compose "$@"
}

system-shell-exec() {
    local service=$1
    local id=$(system-docker-compose ps -q $service)
    shift

    if [[ -z $id ]]; then
        echo "Service $service not available. Run: ops start"
        exit 1
    fi

    ops docker exec -it $id "$@"
}

system-config() {
    #
    # list: config
    # get:  config [key]
    # set:  config [key] [value]
    #

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

system-install-fresh() {
    rm -rf $OPS_HOME

    system-install
}

system-install() {
    if [[  -d $OPS_HOME ]]; then
        return
    fi

    cp -rp $OPS_SCRIPT_DIR/home $OPS_HOME

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

    ops docker build -t ops-node:$OPS_VERSION $OPS_HOME/node
    ops docker build -t ops-utils:$OPS_VERSION $OPS_HOME/utils

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

    ops docker run --rm \
        -v $OPS_HOME:/ops-home \
        -i $OPS_DOCKER_UTILS_IMAGE \
        openssl genrsa -out /ops-home/certs/self-signed-cert.key 2048

    ops docker run --rm \
        -v $OPS_HOME:/ops-home \
        -i $OPS_DOCKER_UTILS_IMAGE \
        openssl req -new -batch -passin pass: \
        -key /ops-home/certs/self-signed-cert.key \
        -out /ops-home/certs/self-signed-cert.csr \
        -config /ops-home/certs/ssl.conf

    ops docker run --rm \
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
    # Regenerate/Restart services. (They might depend on new configs/certs)
    #

    if [[ ! -z $(ops-ps | grep Up) ]]; then
        RUNNING=1
    fi

    system-docker-compose rm -fs

    if [[ ! -z $RUNNING ]]; then
        ops-start
    fi
}

system-start() {
    system-docker-compose up -d
}

system-stop() {
    system-docker-compose stop
}

system-help() {
    cmd-help "ops system" system
    echo
}


# Project Creation

_ops-init() {
    cmd-run init "$@"
}

init-help() {
    cmd-help "ops init" init
    echo

}

init-craft2() {
    local folder=$1
    local domain=${2-"$1.$OPS_DOMAIN"}

    echo 'Installing Craft'

    ops composer create-project imarc/padstone $folder

}

init-laravel() {
    echo
}

# Run Main Command

main() {
    system-install
    validate-config

    cmd-run ops "$@"
    exit
}

main "$@"
