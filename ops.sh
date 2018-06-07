#!/bin/bash
shopt -s extglob

OPS_VERSION=0.5.1

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

# Load config

if [[ -f '.env' ]]; then
    source '.env'
fi

if [[ -f 'ops-commands.sh' ]]; then
    source 'ops-commands.sh'
fi

# options that can't be overidden by a project

OPS_HOME="$HOME/.ops"
OPS_DOCKER_UTILS_IMAGE="ops-utils:$OPS_VERSION"
OPS_DOCKER_APACHE_IMAGE="imarcagency/php-apache:2"
OPS_DOCKER_COMPOSER_IMAGE="imarcagency/php-apache:2"
OPS_DOCKER_NODE_IMAGE="node:8.9.4"
OPS_DOCKER_GID=""
OPS_DOCKER_UID=""
OPS_DOMAIN="imarc.io"
OPS_MINIO_ACCESS_KEY="minio-access"
OPS_MINIO_SECRET_KEY="minio-secret"
OPS_SHELL_COMMAND="bash"
OPS_SHELL_SERVICE="apache"
OPS_SITES_DIR="$HOME/Sites"

# options that can be overridden by a project

OPS_PROJECT_COMPOSE_FILE=${OPS_PROJECT_COMPOSE_FILE-"ops-compose.yml"}
OPS_PROJECT_TEMPLATE=${OPS_PROJECT_TEMPLATE-""}

if [[ -f "$OPS_HOME/config" ]]; then
    source $OPS_HOME/config
fi

# variables that can't be overriden at all
OPS_DASHBOARD_URL="https://ops.${OPS_DOMAIN}"

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
    cmd-help ops ops

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
        --label=ops.project="$(ops project id)" \
        --user "node" \
        --entrypoint "node" \
        ops-node:$OPS_VERSION \
        "$@"
}

_ops-npm() {
    ops docker run \
        --rm -itP --init \
        -v "$(pwd):/usr/src/app" \
        -w "/usr/src/app" \
        --label=ops.project="$(ops project id)" \
        --label=traefik.enable=true \
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
    local id=$(system-docker-compose ps -q $OPS_SHELL_SERVICE)
    local project=$(project-name)

    [[ -z $id ]] && exit

    ops docker exec -w "/var/www/html/$project" -u www-data -it $id "$OPS_SHELL_COMMAND"
}

ops-link() {
    local project_name=$(project-name)

    if [[ -z $project_name ]]; then
        echo 'No project found.'
        exit 1
    fi

    echo "Linking $project_name."

    project-start "$@"
}

ops-unlink() {
    local project_name=$(project-name)

    if [[ -z $project_name ]]; then
        echo 'No project found.'
        exit 1
    fi

    echo "Unlinking $project_name."

    project-docker-compose rm -sv "$@"
}

ops-project() {
    cmd-run project "$@"
}

ops-stats() {
    local ids=$(system-docker-compose ps -q)
    [[ -z $ids ]] && exit
    ops docker stats $ids
}

ops-start() {
    echo 'Starting ops services...'
    echo

    validate-config
    system-start

    local info=$(docker ps -a --format '{{.ID}} {{.Label "ops.project"}}' --filter="label=ops.project")

    IFS=$'\n'
    for container in $info; do
        IFS=' '

        # https://stackoverflow.com/a/1478245
        set $container

        if [[ $2 != 'ops' ]] && [[ -e "$OPS_SITES_DIR/$2" ]]; then
            (
                cd $OPS_SITES_DIR/$2
                ops project start
            )
        fi
    done

    echo
    echo "Visit your dashboard: ${OPS_DASHBOARD_URL}"
    echo
}

ops-stop() {
    system-stop

    local info=$(docker ps -a --format '{{.ID}} {{.Label "ops.project"}}' --filter="label=ops.project")

    IFS=$'\n'
    for container in $info; do
        IFS=' '

        # https://stackoverflow.com/a/1478245
        set $container

        if [[ $2 == 'ops' ]]; then
            continue
        fi

        if [[ -e "$OPS_SITES_DIR/$2" ]]; then
            (
                cd $OPS_SITES_DIR/$2
                ops project stop
            )
        else
            docker stop $1 1> /dev/null
        fi
    done
}

ops-sync() {
    # Ops sync assumes the following:
    #
    # - SSH access is enabled to the remote web and/or DB servers
    # - DB servers make their tools available to the SSH user: mysqldump, pg_dump, etc.

    RSYNC_BIN=$(which rsync)

    if [[ -z "$RSYNC_BIN" ]]; then
        echo 'Rsync is a required dependency. Please install.'
        exit 1
    fi

    # do the following work in a subshell so
    # dir switching is a little more graceful

    (

    OPS_PROJECT_NAME="$(ops project name)"

    cd "$OPS_SITES_DIR/$OPS_PROJECT_NAME"
    source ".env"

    OPS_PROJECT_DB_TYPE="${OPS_PROJECT_DB_TYPE}"
    OPS_PROJECT_DB_NAME="${OPS_PROJECT_DB_NAME-$OPS_PROJECT_NAME}"

    OPS_PROJECT_SYNC_DIRS="${OPS_PROJECT_SYNC_DIRS}"
    OPS_PROJECT_SYNC_NODB="${OPS_PROJECT_SYNC_NODB-0}"
    OPS_PROJECT_SYNC_EXCLUDES="${OPS_PROJECT_SYNC_EXCLUDES}"
    OPS_PROJECT_SYNC_MAXSIZE="${OPS_PROJECT_SYNC_MAXSIZE-500M}"

    OPS_PROJECT_REMOTE_USER="${OPS_PROJECT_REMOTE_USER}"
    OPS_PROJECT_REMOTE_HOST="${OPS_PROJECT_REMOTE_HOST-$OPS_PROJECT_NAME}"
    OPS_PROJECT_REMOTE_PATH="${OPS_PROJECT_REMOTE_PATH}"
    OPS_PROJECT_REMOTE_DB_HOST="${OPS_PROJECT_REMOTE_HOST}"
    OPS_PROJECT_REMOTE_DB_TYPE="${OPS_PROJECT_DB_TYPE-$OPS_PROJECT_DB_TYPE}"
    OPS_PROJECT_REMOTE_DB_NAME="${OPS_PROJECT_REMOTE_DB_NAME-$OPS_PROJECT_DB_NAME}"
    OPS_PROJECT_REMOTE_DB_USER="${OPS_PROJECT_REMOTE_DB_USER-$OPS_PROJECT_REMOTE_USER}"

    # best debugging helper
    # ( set -o posix ; set ) | grep -E '^OPS_'

    local ssh_host="$([[ ! -z $OPS_PROJECT_REMOTE_DB_USER ]] && echo "$OPS_PROJECT_REMOTE_DB_USER@")"
    local ssh_host="$ssh_host$OPS_PROJECT_REMOTE_HOST"
    local timestamp="$(date '+%Y%m%d')"
    local dumpfile="$OPS_PROJECT_NAME-$timestamp.sql"

    # sync database

    if \
        [[ $OPS_PROJECT_SYNC_NODB == 0 ]] && \
        [[ ! -z "$OPS_PROJECT_DB_NAME" ]] && \
        [[ ! -z "$OPS_PROJECT_DB_TYPE" ]] && \
        [[ ! -z "$OPS_PROJECT_REMOTE_DB_TYPE" ]] && \
        [[ ! -z "$OPS_PROJECT_REMOTE_DB_HOST" ]] && \
        [[ ! -z "$OPS_PROJECT_REMOTE_DB_NAME" ]] && \
        [[ ! -z "$OPS_PROJECT_REMOTE_DB_USER" ]]
    then
        if [[ "$OPS_PROJECT_REMOTE_DB_TYPE" = "mariadb" ]]; then
            echo "Syncing remote mariadb database '$OPS_PROJECT_REMOTE_DB_NAME' to $dumpfile"
            ssh -TC "$ssh_host" "mysqldump --single-transaction $OPS_PROJECT_REMOTE_DB_NAME" > $dumpfile
            echo "Importing $dumpfile to '$OPS_PROJECT_DB_NAME' mariadb database"
            ops-mariadb-import "$OPS_PROJECT_DB_NAME" $dumpfile

        elif [[ "$OPS_PROJECT_REMOTE_DB_TYPE" = "pgsql" ]]; then
            echo "Syncing remote pgsql database '$OPS_PROJECT_REMOTE_DB_NAME' to $dumpfile"
            ssh -TC "$ssh_host" "pg_dump $OPS_PROJECT_REMOTE_DB_NAME" > $dumpfile
            echo "Importing $dumpfile to '$OPS_PROJECT_DB_NAME' pgsql database"
            ops-psql-import "$OPS_PROJECT_DB_NAME" $dumpfile
        fi
    fi

    # sync filesystem

    if \
        [[ ! -z "$OPS_PROJECT_REMOTE_HOST" ]] && \
        [[ ! -z "$OPS_PROJECT_REMOTE_PATH" ]] && \
        [[ ! -z "$OPS_PROJECT_SYNC_DIRS" ]]
    then
        echo $OPS_PROJECT_REMOTE_PATH

        for sync_dir in $OPS_PROJECT_SYNC_DIRS; do
            echo -e "Syncing filesystem: $sync_dir"

            # send exclude patterns as stdin, one per line.
            $(echo "${OPS_PROJECT_SYNC_EXCLUDES// /$'\n'}" | \
                rsync -a --exclude-from=- \
                    --max-size=$OPS_PROJECT_SYNC_MAXSIZE \
                    "$ssh_host:$OPS_PROJECT_REMOTE_PATH/$sync_dir/" \
                    "$sync_dir")
        done
    fi

    )
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
        --label=ops.project="$(ops project name)" \
        --user "node" \
        --entrypoint "yarn" \
        ops-node:$OPS_VERSION \
        "$@"
}

# Site sub sommands

project-docker-compose() {
    if [[ ! -f $OPS_PROJECT_COMPOSE_FILE ]] && [[ ! -z "$OPS_PROJECT_TEMPLATE" ]] && [[ -f "$OPS_HOME/templates/$OPS_PROJECT_TEMPLATE.yml" ]]; then
        OPS_PROJECT_COMPOSE_FILE="$OPS_HOME/templates/$OPS_PROJECT_TEMPLATE.yml"
        echo "Using template: $OPS_PROJECT_TEMPLATE"
    fi

    OPS_DOCKER_UID=$OPS_DOCKER_UID \
    OPS_DOCKER_GID=$OPS_DOCKER_GID \
    OPS_DOMAIN=$OPS_DOMAIN \
    OPS_PROJECT_NAME="$(basename $PWD)" \
    OPS_VERSION=$OPS_VERSION \
    COMPOSE_PROJECT_NAME="ops$(basename $PWD)" \
    COMPOSE_FILE="$OPS_PROJECT_COMPOSE_FILE" \
    docker-compose --project-directory . "$@"
}

project-name() {
    if [[ "$(pwd)" != $OPS_SITES_DIR/* ]]; then
        exit 1
    fi

    echo $(
        local basename="$(basename $(pwd))"
        while [[ "$(pwd)" != $OPS_SITES_DIR ]] && [[ "$(pwd)" != '/' ]]; do
            basename=$(basename $(pwd))
            cd ..
        done
        echo $basename
    )
}

project-start() {
    project-docker-compose up -d
}

project-stop() {
    project-docker-compose stop
}

project-logs() {
    project-docker-compose logs -f "$@"
}

project-ps() {
    project-docker-compose ps "$@"
}

project-exec() {
    local service=$1
    shift

    local id=$(project-docker-compose ps -q $service)

    [[ -z $id ]] && exit

    ops docker exec -i $id "$@"
}

project-help() {
    cmd-help "ops project" project
    echo
}

project-shell-exec() {
    local id=$(project-docker-compose ps -q $1)
    shift

    [[ -z $id ]] && exit

    ops docker exec -it $id "$@"
}

project-stats() {
    local ids=$(project-docker-compose ps -q)
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
    OPS_VERSION=$OPS_VERSION \
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
        sed -i ' ' -e "s#^$key=.*#$key=\"$val\"#" "$OPS_HOME/config"
    elif [[ -n $key ]]; then
        cat $OPS_HOME/config | awk "/^$1=(.*)/ { sub(/$1=/, \"\", \$0); print }"
    else
        cat $OPS_HOME/config
    fi
}

system-update() {
    if [[ ! -d $OPS_HOME ]]; then
        system-install
        return
    fi

    shopt -s extglob
    cp -rp $OPS_SCRIPT_DIR/home/!(config) $OPS_HOME
    shopt -u extglob

    system-refresh-config
    system-refresh-services
}

system-install() {
    if [[ -d $OPS_HOME ]]; then
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

    system-refresh-config
    system-refresh-certs
    system-refresh-services
}

system-refresh-certs() {
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


}

system-refresh-config() {
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
}

system-refresh-services() {
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
    # removing apache is a hacky mod_lua crash fix. this issue seems to happen
    # when containers are left running on a restart with docker for mac. if not
    # remedied, the apache container refuses to start up again.
    system-docker-compose rm -fs apache &> /dev/null

    system-docker-compose up -d --remove-orphans
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
