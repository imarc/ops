#!/usr/bin/env bash

shopt -s extglob

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
    echo "Unsupported operating system. Use Macintosh, Linux, or WSL."
    exit 1
fi

# Find script dir (and resolve symlinks)

declare -rx OPS_WORKING_DIR=$(pwd)
cd $(dirname $0)
cd $(dirname $(ls -l $0 | awk '{print $NF}'))
declare -rx OPS_SCRIPT_DIR=$(pwd)
cd $OPS_WORKING_DIR

# get version from VERSION file

declare -rx OPS_VERSION=$(cat $OPS_SCRIPT_DIR/VERSION)

# Include cmd helpers

source $OPS_SCRIPT_DIR/cmd.sh

# Internal helpers

bold() { echo "$(tput bold)$*$(tput sgr0)"; }
under() { echo "$(tput smul)$*$(tput rmul)"; }

validate-config() {
    errors=()

    if [[ ! -d $OPS_HOME ]]; then
        echo
        echo "Ops not installed. Please run: $(bold ops system install)"
        echo
        exit 1
    fi

    if [[ -z $OPS_SITES_DIR ]]; then
        errors+=("$(bold OPS_SITES_DIR) is not set in your ops config.")
    fi

    if [[ ! -d $OPS_SITES_DIR ]]; then
        errors+=("$(bold OPS_SITES_DIR) \"$OPS_SITES_DIR\" doesn't exist.")
    fi

    if [[ -z $OPS_DOMAIN ]]; then
        errors+=("$(bold OPS_DOMAIN) is not set in your ops config.")
    fi

    if [[ -n $errors ]]; then
        echo "The following errors need to be addressed:"
        echo
        printf " - %s\n" "${errors[@]}"
        echo
        exit 1
    fi


    #if [[ -f $OPS_HOME/VERSION ]] && version-greater-than $OPS_VERSION $(cat $OPS_HOME/VERSION); then
    #    echo "Ops needs to update"
    #    system-install
    #fi

}

version-greater-than() {
    # version-greater-than v1 v2
    test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1";
}

get-version() {
    awk 'match($0, /([0-9][0-9\.a-z-]+)/) { print substr($0, RSTART, RLENGTH) }'
}

# Main Commands

ops-composer() {
    cmd-doc "Run local composer. Fallback to running composer via docker."

    if [[ -e "$(which composer)" ]]; then
        composer "$@"
        return;
    fi

    if [[ $OS != 'linux' ]]; then
        echo 'Running composer via docker is only supported on linux. Please install composer.'
        exit 1
    fi

    mkdir -p "$OPS_HOME/.composer"
    mkdir -p "$OPS_HOME/.ssh"

    local project="$(ops project name)"

    _ops-docker run \
        --rm -itP \
        -v "$(pwd):/var/www/html/$project" \
        -v "$HOME/.composer:/var/www/.composer" \
        -v "$HOME/.ssh:/var/www/.ssh" \
        -v "$ssh_agent:/ssh-agent" \
        -e "SSH_AUTH_SOCK=/ssh-agent" \
        -e "COMPOSER_HOME=/var/www/.composer" \
        -w "/var/www/html/$project" \
        --label=ops.project="$project" \
        --user "$OPS_DOCKER_UID:$OPS_DOCKER_GID" \
        $OPS_DOCKER_COMPOSER_IMAGE \
        composer -n "$@"
}

_ops-docker() {
    docker "$@"
}

ops-exec() {
    cmd-doc "Execute a non-TTY (non-interactive) command in a container."

    local service=$1
    shift

    local id=$(system-docker-compose ps -q $service)

    [[ -z $id ]] && exit

    _ops-docker exec -i $id "$@"
}

ops-help--after() {
    echo $(ops-version)
    echo
}

ops-logs() {
    cmd-doc "Tail (display) logs."

    system-docker-compose logs -f --tail="30" "$@"
}

ops-env() {
    cmd-doc "Set or get a variable in the current project's .env file."

    #
    # list: env
    # get:  env [key]
    # set:  env [key] [value]
    #

    local key=$1
    shift
    local val=$(local IFS=" "; echo "$@");

    if [[ ! -e ".env" ]]; then
        exit 1
    fi

    if [[ -n $key && -n $val ]]; then
        if [[ -n $(grep -E "^$key=" .env) ]]; then
            sed -i -e "s#^$key=.*#$key=\"$val\"#" .env
        else
            echo "$key=\"$val\"" >> .env
        fi
    elif [[ -n $key ]]; then
        cat .env | awk "/^$key=(.*)/ { sub(/$key=/, \"\", \$0); print }"
    else
        cat .env
    fi
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
    cmd-doc "MariaDB-specific commands."

    cmd-run mariadb "$@"
}

mariadb-help() {
    cmd-help "ops mariadb" mariadb
    echo
}

mariadb-cli() {
    system-shell-exec mariadb mysql "${@}"
}

mariadb-run() {
    ops-exec mariadb mysql "${@}"
}

mariadb-create() {
    local db="$1"

    mariadb-cli -e "CREATE DATABASE $1"

    if [[ $? == 0 ]]; then
        echo "Created mariadb database: $1"
    fi
}

mariadb-list() {
    ops-exec mariadb mysql --column-names=FALSE -e "show databases;" | \
        grep -v "^information_schema$" | \
        grep -v "^performance_schema$" | \
        grep -v "^mysql$"
}

mariadb-export() {
    local db="$1"

    ops-exec mariadb mysqldump --single-transaction --add-drop-table "$db"
}

mariadb-import() {
    local db="$1"
    local sqlfile=${2--}


    (
        # don't let these commands grab stdin
        ops-exec mariadb mysql -e "DROP DATABASE IF EXISTS $db"
        ops-exec mariadb mysql -e "CREATE DATABASE $db"
    ) </dev/null

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

ops-npm() {
    cmd-doc "Run local npm. Fallback to running npm via docker."

    if [[ -e "$(which npm)" ]]; then
        npm "$@"
        return;
    fi

    if [[ $OS != 'linux' ]]; then
        echo 'Running npm via docker is only supported on linux. Please install npm.'
        exit 1
    fi

    local project="$(ops project name)"

    ops docker run \
        --rm -itP --init \
        -v "$(pwd):/var/www/html/$project" \
        -v "$HOME/.composer:/var/www/.composer" \
        -v "$HOME/.ssh:/var/www/.ssh" \
        -v "$ssh_agent:/ssh-agent" \
        -e "SSH_AUTH_SOCK=/ssh-agent" \
        -e "COMPOSER_HOME=/var/www/.composer" \
        -w "/var/www/html/$project" \
        --label=ops.project="$project" \
        --user "$OPS_DOCKER_UID:$OPS_DOCKER_GID" \
        --entrypoint "npm" \
        ops-node:$OPS_VERSION \
        "$@"
}

_ops-package() {
    local project_name=$(project-name)
    local project_path="$OPS_SITES_DIR/$project_name"

    cp $OPS_HOME/build/Dockerfile $project_path/_temp-ops-Dockerfile

    docker build -f _temp-ops-Dockerfile -t $project_name:latest --no-cache \
        --build-arg OPS_PROJECT_IMAGE="imarcagency/ops-$OPS_PROJECT_BACKEND:$OPS_VERSION" \
        --build-arg OPS_PROJECT_DOCROOT="$OPS_PROJECT_DOCROOT" \
        $project_path

    rm _temp-ops-Dockerfile
}

ops-ps() {
    cmd-doc "Display the status of all ops containers."

    system-docker-compose ps "$@"
}

psql-cli() {
    system-shell-exec postgres psql -U postgres "$@"
}

psql-create() {
    local db="$1"

    psql-cli -c "CREATE DATABASE $1" 1> /dev/null

    if [[ $? == 0 ]]; then
        echo "Created postgres database: $1"
    fi
}

psql-run() {
    ops-exec postgres psql -U postgres "${@}"
}

psql-list() {
    ops-exec postgres psql -U postgres -t -c "SELECT datname FROM pg_database WHERE datname NOT IN ('template0', 'template1', 'postgres')" | \
    sed -e "s/^ *//" -e "/^$/d"
}

psql-export() {
    local db="$1"

    ops-exec postgres pg_dump -U postgres "$db"
}

psql-import() {
    local db="$1"
    local sqlfile=${2--}

    (
        # don't let these commands capture stdin
        ops-exec postgres psql -U postgres -c "DROP DATABASE IF EXISTS $db"
        ops-exec postgres psql -U postgres -c "CREATE DATABASE $db"
    ) </dev/null

    cat "$sqlfile" | ops-exec postgres psql -U postgres "$db"
}

psql-help() {
    cmd-help "ops psql" psql
    echo
}

ops-psql() {
    cmd-doc "PostreSQL-specific commands."

    cmd-run psql "$@"
}

_ops-lt() {
    local project="$(ops project name)"

    echo "$project.$OPS_DOMAIN"

    ops docker run \
        --rm --init -itP \
        --label=ops.project="$project" \
        --network=host \
        efrecon/localtunnel \
            --local-host="$project.$OPS_DOMAIN" \
            --port=80

        #ops-utils:$OPS_VERSION bash \
}

_ops-gulp() {
    ops docker run \
        --rm -itP --init \
        -v "$(pwd):/usr/src/app" \
        -w "/usr/src/app" \
        --label=ops.project="$(ops project id)" \
        --user "node" \
        --entrypoint "gulp" \
        ops-node:$OPS_VERSION \
        "$@"
}

ops-redis() {
    cmd-doc "Run interactive redis cli."

    system-shell-exec redis redis-cli "$@"
}

ops-restart() {
    cmd-doc "Restart all running containers."
    ops-stop

    ops-start
}

ops-shell() {
    cmd-doc "Enter shell or execute a command within the webserver's container."

    local id=$(system-docker-compose ps -q $OPS_SHELL_BACKEND)
    local project=$(project-name)
    local command="$OPS_SHELL_COMMAND"

    if [[ -z "$project" ]]; then
        echo "$(bold ops shell) must be run from a project directory."
        exit
    fi

    if [[ -z "$id" ]]; then
        echo "Unable to determine the container ID for current project's backend."
        exit
    fi

    if [[ ! -z "$1" ]]; then
        command="$@"
    fi

    _ops-docker exec -w "/var/www/html/$project" -u "$OPS_SHELL_USER" -it $id $command
}

ops-link() {
    cmd-doc "Link and start project-specific containers"

    local project_name=$(project-name)

    if [[ -z $project_name ]]; then
        echo 'No project found.'
        exit 1
    fi

    echo "Linking $project_name."

    project-start "$@" --remove-orphans
}

ops-unlink() {
    cmd-doc "Unlink and stop project-specific containers"

    local project_name=$(project-name)

    if [[ -z $project_name ]]; then
        echo 'No project found.'
        exit 1
    fi

    echo "Unlinking $project_name."

    project-docker-compose rm -sv "$@"
}

ops-project() {
    cmd-doc "Project-specific commands"

    cmd-run project "$@"
}

ops-stats() {
    cmd-doc "Watch service stats"

    local ids=$(system-docker-compose ps -q)

    if [[ -z $ids ]]; then
        exit
    fi

    _ops-docker stats $ids
}

ops-start() {
    cmd-doc "Start services"

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
                project-start
            )
        fi
    done

    echo
    echo "Visit your dashboard: ${OPS_DASHBOARD_URL}"
    echo
}

ops-stop() {
    cmd-doc "Stop services"

    system-stop

    local info=$(_ops-docker ps -a --format '{{.ID}} {{.Label "ops.project"}}' --filter="label=ops.project")

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
    cmd-doc "Sync remote databases/files to local project"

    # Ops sync assumes the following:
    #
    # - SSH access is enabled to the remote web and/or DB servers
    # - DB servers make their tools available to the SSH user: mysqldump, pg_dump, etc.
    # - the SSH user has passwordless access to databases from localhost

    RSYNC_BIN=$(which rsync)

    if [[ -z "$RSYNC_BIN" ]]; then
        echo 'Rsync is a required dependency. Please install.'
        exit 1
    fi

    # do the following work in a subshell so
    # dir switching is a little more graceful

    (

    if [[ -z "$OPS_PROJECT_NAME" ]]; then
        echo "sync must be run from a project directory"
    fi

    cd "$OPS_SITES_DIR/$OPS_PROJECT_NAME"
    #source ".env"

    # best debugging helper
    # ( set -o posix ; set ) | grep -E '^OPS_'
    local ssh_host="$([[ ! -z $OPS_PROJECT_REMOTE_USER ]] && echo "$OPS_PROJECT_REMOTE_USER@")"
    local ssh_host="$ssh_host$OPS_PROJECT_REMOTE_HOST"

    if [[ ! -z "$OPS_DEBUG" ]]; then
        # print out all OPS_ vars
        echo
        echo '=== START DEBUG ==='
        ( set -o posix ; set ) | grep -E '^OPS_'
        echo '=== END DEBUG ==='
        echo
    fi

    # sync database
    if \
        [[ $OPS_PROJECT_SYNC_NODB == 0 ]] && \
        [[ ! -z "$OPS_PROJECT_DB_NAME" ]] && \
        [[ ! -z "$OPS_PROJECT_DB_TYPE" ]] && \
        [[ ! -z "$OPS_PROJECT_REMOTE_DB_TYPE" ]] && \
        [[ ! -z "$OPS_PROJECT_REMOTE_DB_NAME" ]]
    then
        if [[ "$OPS_PROJECT_REMOTE_OPS" != 0 ]]; then
            echo "Syncing remote mariadb '$OPS_PROJECT_REMOTE_DB_NAME' to local '$OPS_PROJECT_DB_NAME'"

            ssh -C "$ssh_host" \
                "ops $OPS_PROJECT_REMOTE_DB_TYPE export $OPS_PROJECT_REMOTE_DB_NAME" | \
                $OPS_PROJECT_DB_TYPE-import "$OPS_PROJECT_DB_NAME"

        elif [[ "$OPS_PROJECT_REMOTE_DB_TYPE" = "mariadb" ]]; then
            echo "Syncing remote mariadb '$OPS_PROJECT_REMOTE_DB_NAME' to local '$OPS_PROJECT_DB_NAME'"

            local mysqldump_password="$([[ ! -z $OPS_PROJECT_REMOTE_DB_PASSWORD ]] && echo "-p$OPS_PROJECT_REMOTE_DB_PASSWORD")"
            local mysqldump_host="$([[ ! -z $OPS_PROJECT_REMOTE_DB_HOST ]] && echo "-h $OPS_PROJECT_REMOTE_DB_HOST")"
            local mysqldump_port="$([[ ! -z $OPS_PROJECT_REMOTE_DB_PORT ]] && echo "-P $OPS_PROJECT_REMOTE_DB_PORT")"
            local mysqldump_user="$([[ ! -z $OPS_PROJECT_REMOTE_DB_USER ]] && echo "-u $OPS_PROJECT_REMOTE_DB_USER")"

            ssh -C "$ssh_host" "mysqldump --single-transaction \
                $mysqldump_port \
                $mysqldump_host \
                $mysqldump_user \
                $mysqldump_password \
                $OPS_PROJECT_REMOTE_DB_NAME" 2>/dev/null | \
                    mariadb-import "$OPS_PROJECT_DB_NAME"

        elif [[ "$OPS_PROJECT_REMOTE_DB_TYPE" = "psql" ]]; then
            OPS_PROJECT_REMOTE_DB_PORT="${OPS_PROJECT_REMOTE_DB_PORT:-"5432"}"

            echo "Importing database from $OPS_PROJECT_REMOTE_DB_NAME to '$OPS_PROJECT_DB_NAME' pgsql database"

            #local pgdump_password="$([[ ! -z $OPS_PROJECT_REMOTE_DB_PASSWORD ]] && echo "-p$OPS_PROJECT_REMOTE_DB_PASSWORD")"
            local pgdump_host="$([[ ! -z $OPS_PROJECT_REMOTE_DB_HOST ]] && echo "-h $OPS_PROJECT_REMOTE_DB_HOST")"
            #local pgdump_port="$([[ ! -z $OPS_PROJECT_REMOTE_DB_PORT ]] && echo "-P $OPS_PROJECT_REMOTE_DB_PORT")"
            #local pgdump_user="$([[ ! -z $OPS_PROJECT_REMOTE_DB_USER ]] && echo "-u $OPS_PROJECT_REMOTE_DB_USER")"

            ssh -TC "$ssh_host" "pg_dump \
                $pgdump_host \
                $OPS_PROJECT_REMOTE_DB_NAME" 2>/dev/null | \
                    psql-import "$OPS_PROJECT_DB_NAME"
        fi
    fi

    # sync filesystem

    local max_size="$([[ ! -z $OPS_PROJECT_SYNC_MAXSIZE ]] && echo "--max-size=$OPS_PROJECT_SYNC_MAXSIZE")"

    if \
        [[ ! -z "$OPS_PROJECT_REMOTE_HOST" ]] && \
        [[ ! -z "$OPS_PROJECT_REMOTE_PATH" ]] && \
        [[ ! -z "$OPS_PROJECT_SYNC_DIRS" ]]
    then
        for sync_dir in $OPS_PROJECT_SYNC_DIRS; do
            echo -e "Syncing filesystem: $sync_dir"
            echo -e "Syncing directory structure..."

            # sync entire dir structure first
            rsync -a -f"+ */" -f"- *" \
                "$ssh_host:$OPS_PROJECT_REMOTE_PATH/$sync_dir/" \
                "$sync_dir" 1>/dev/null

            echo -e "Syncing files..."

            # send exclude patterns as stdin, one per line.
            printf %"s\n" $OPS_PROJECT_SYNC_EXCLUDES | \
                rsync -av --exclude-from=- \
                    --timeout=5 \
                    $max_size \
                    "$ssh_host:$OPS_PROJECT_REMOTE_PATH/$sync_dir/" \
                    "$sync_dir"
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
    cmd-doc "System-specific commands"

    cmd-run system "$@"
}

ops-version() {
    cmd-doc "Show ops version"

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
    local project_name=$(project-name)

    OPS_PROJECT_NAME="$project_name" \
    COMPOSE_PROJECT_NAME="ops-$project_name" \
    COMPOSE_FILE="$OPS_PROJECT_COMPOSE_FILE" \
    docker-compose --project-directory "$OPS_SITES_DIR/$project_name" "$@"
}

project-ls() {
    cmd-doc "List all projects in OPS_SITES_DIR"


    (
        cd $OPS_SITES_DIR
        ls -d -1 */ 2>/dev/null | sed 's/\/$//'
    )
}

project-name() {
    if [[ "$(pwd)" != $OPS_SITES_DIR/* ]]; then
        exit 1
    else
        echo $(
            local basename="$(basename $(pwd))"
            while [[ "$(pwd)" != $OPS_SITES_DIR ]] && [[ "$(pwd)" != '/' ]]; do
                basename=$(basename $(pwd))
                cd ..
            done
            echo -n $basename
        )
    fi
}

project-start() {
    project-docker-compose up -d --force-recreate "$@"
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

    if [[ -z $id ]]; then
        exit
    fi

    _ops-docker exec -i $id "$@"
}

project-help() {
    cmd-help "ops project" project "$@"
    echo
}

project-shell-exec() {
    local id=$(project-docker-compose ps -q $1)
    shift

    if [[ -z $id ]]; then
        exit
    fi

    _ops-docker exec -it $id "$@"
}

project-stats() {
    local ids=$(project-docker-compose ps -q)

    if [[ -z $id ]]; then
        exit
    fi

    _ops-docker stats $ids
}

# System Sub-Commands

system-docker-compose() {
    COMPOSE_FILE="$OPS_HOME/docker-compose/system/base.yml"
    #COMPOSE_FILE="$COMPOSE_FILE:$OPS_HOME/docker-compose/services/traefik.yml"

    for service in $OPS_SERVICES; do
        COMPOSE_FILE="$COMPOSE_FILE:$OPS_HOME/docker-compose/services/$service.yml"
    done

    for backend in $OPS_BACKENDS; do
        COMPOSE_FILE="$COMPOSE_FILE:$OPS_HOME/docker-compose/backends/$backend.yml"
    done

    if [[ ! -z "$OPS_PUBLIC" ]]; then
	    COMPOSE_FILE="$COMPOSE_FILE:$OPS_HOME/docker-compose/system/public.yml"
    else
	    COMPOSE_FILE="$COMPOSE_FILE:$OPS_HOME/docker-compose/system/private.yml"
    fi


    COMPOSE_PROJECT_NAME="ops" \
    COMPOSE_FILE=$COMPOSE_FILE \
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

    _ops-docker exec -it $id "$@"
}

system-check() {
    echo -n "docker: "
    if [[ -z $(which docker) ]]; then
        echo "not found"
    elif ! version-greater-than $(docker --version | get-version) $OPS_DOCKER_VERSION; then
        echo "version must be at least 18.00.0"
    else
        echo "found"
    fi

    echo -n "docker-compose: "
    if [[ -z $(which docker-compose) ]]; then
        echo "not found"
    elif ! version-greater-than $(docker-compose --version | get-version) $OPS_DOCKER_COMPOSE_VERSION; then
        echo "version must be at least 1.22.0"
    else
        echo "found"
    fi

    echo -n "rsync: "
    if [[ -z $(which rsync) ]]; then
        echo "not found"
    else
        echo "found"
    fi

    echo -n "ssh: "
    if [[ -z $(which ssh) ]]; then
        echo "not found"
    else
        echo "found"
    fi

    if [[ "$OS" == linux ]]; then
        echo -n "certutil: "
        if [[ -z $(which certutil) ]]; then
            echo "not found"
        else
            echo "found"
        fi
    fi
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
        if [[ -n $(system-config $key) ]]; then
            sed -i '' -e "s#^$key=.*#$key=\"$val\"#" "$OPS_HOME/config"
        else
            echo "$key=\"$val\"" >> $OPS_HOME/config
        fi
    elif [[ -n $key ]]; then
        cat $OPS_HOME/config | awk "/^$key=(.*)/ { sub(/$key=/, \"\", \$0); print }"
    else
        cat $OPS_HOME/config
    fi
}

system-install() {
    if [[ ! -d $OPS_HOME ]]; then
        cp -R $OPS_SCRIPT_DIR/home $OPS_HOME

        source $OPS_HOME/config

        if [[ "$OS" == linux ]]; then
            local whoami="$(whoami)"

            system-config OPS_DOCKER_UID "$(id -u $whoami)"
            system-config OPS_DOCKER_GID "$(id -g $whoami)"
        fi
    else
        mkdir -p $OPS_HOME/bin
        mkdir -p $OPS_HOME/certs

        rsync -a \
          --exclude=/bin \
          --exclude=/certs \
          --exclude=/config \
          --exclude=acme.json \
          $OPS_SCRIPT_DIR/home/ \
          $OPS_HOME
    fi

    echo $OPS_VERSION > $OPS_HOME/VERSION

    source $OPS_HOME/config

    system-install-mkcert

    if [[ ! -f "$OPS_HOME/certs/self-signed-cert.key" ]]; then
        system-refresh-certs
        exit
    fi

    #system-refresh-services
}

system-install-mkcert() {
    if [[ ! -d $OPS_HOME ]]; then
        return
    fi

    if [[ -f $OPS_HOME/bin/mkcert-$OPS_MKCERT_VERSION ]]; then
        return
    fi

    rm -f $OPS_HOME/bin/mkcert-*

    if [[ "$OS" == linux ]]; then
        MKCERT_URL="https://github.com/FiloSottile/mkcert/releases/download/v$OPS_MKCERT_VERSION/mkcert-v$OPS_MKCERT_VERSION-linux-amd64"
    elif [[ "$OS" == mac ]]; then
        MKCERT_URL="https://github.com/FiloSottile/mkcert/releases/download/v$OPS_MKCERT_VERSION/mkcert-v$OPS_MKCERT_VERSION-darwin-amd64"
    fi

    echo "Downloading mkcert v$OPS_MKCERT_VERSION"
    curl -L --silent --output $OPS_HOME/bin/mkcert-$OPS_MKCERT_VERSION $MKCERT_URL
    chmod 744 $OPS_HOME/bin/mkcert-$OPS_MKCERT_VERSION
}

system-refresh-certs() {
    sudo --non-interactive echo 2> /dev/null

    if [[ $? == 1 ]]; then
        echo
        echo 'Installing self-signed certs for valid HTTPS support.'
        sudo --prompt="Enter your system/sudo password: " echo

        if [[ $? == 1 ]]; then
            echo 'Invalid password. Certs were not generated :('
            echo 'Ops could not be installed'

            exit 1
        fi
    fi

    local project_domains=""
    local project_count=$(project-ls | wc -l)

    for project in $(project-ls); do
        project_domains+=" *.$project.$OPS_DOMAIN"
    done

    (
        cd $OPS_HOME/certs

        CAROOT=$OPS_HOME/certs \
        $OPS_HOME/bin/mkcert-$OPS_MKCERT_VERSION -install

        CAROOT=$OPS_HOME/certs \
        $OPS_HOME/bin/mkcert-$OPS_MKCERT_VERSION \
            localhost \
            "$OPS_DOMAIN" \
            "*.$OPS_DOMAIN" \
            "*.ops.$OPS_DOMAIN" \
            $project_domains

        local domain_count=$(expr $project_count + 3)

        mv "localhost+$domain_count-key.pem" self-signed-cert.key
        mv "localhost+$domain_count.pem" self-signed-cert.crt
    )


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

system-reset() {
    # remove all containers on every start
    system-docker-compose rm -fs &> /dev/null

    # remove all networks
    _ops-docker network rm ops_backend &> /dev/null
    _ops-docker network rm ops_gateway &> /dev/null
    _ops-docker network rm ops_services &> /dev/null


    # TODO inspect networks and point
    # docker network inspect -f '{{range .IPAM.Config}}{{ $.Name }} {{.Subnet}}{{end}}' $(docker network ls -q) | sed '/^$/d'


    # create networks
    _ops-docker network create --subnet="$OPS_SERVICES_SUBNET" ops_services &> /dev/null
    _ops-docker network create ops_backend &> /dev/null
    _ops-docker network create ops_gateway &> /dev/null
}

system-start() {
    system-reset

    # refresh config
    sed \
        -e "s/OPS_DOMAIN/$OPS_DOMAIN/" \
        -e "s/OPS_SERVICES_TRAEFIK_IP/$OPS_SERVICES_TRAEFIK_IP/" \
        $OPS_HOME/dnsmasq/dnsmasq.conf.tmpl > $OPS_HOME/dnsmasq/dnsmasq.conf

    sed \
        -e "s/OPS_MINIO_ACCESS_KEY/$OPS_MINIO_ACCESS_KEY/" \
        -e "s/OPS_MINIO_SECRET_KEY/$OPS_MINIO_SECRET_KEY/" \
        $OPS_HOME/minio/config.json.tmpl > $OPS_HOME/minio/config.json

    # start all services
    system-docker-compose up -d --remove-orphans
}

system-stop() {
    system-docker-compose stop
}

system-help() {
    cmd-help "ops system" system "$@"
    echo
}

main() {
    if [[ "$@" != "system install" ]]; then
        docker ps > /dev/null

        if [[ $? != 0 ]]; then
            exit
        fi

        validate-config
    fi

    declare -x OPS_SERVICES_DNS_IP="$(echo -n $OPS_SERVICES_SUBNET | cut -f1,2 -d'.' | sed 's/$/.10.10/')"
    declare -x OPS_SERVICES_TRAEFIK_IP="$(echo -n $OPS_SERVICES_SUBNET | cut -f1,2 -d'.' | sed 's/$/.10.11/')"

    cmd-run ops "$@"
    exit
}

# options that can be overidden by environment

export OPS_HOME=${OPS_HOME-"$HOME/.ops"}

# load config

if [[ -f "$OPS_HOME/config" ]]; then
    source $OPS_HOME/config

    # generate a literal (non-quoted) version for docker-compose
    # https://github.com/docker/compose/issues/3702
    cat $OPS_HOME/config |
        sed -e '/^$/d' -e '/^#/d' |
	xargs -n1 echo > $OPS_HOME/config.literal
fi


# options that can be overridden by global config

declare -x OPS_ENV="dev"
declare -x OPS_DEBUG="${OPS_DEBUG}"
declare -x OPS_BACKENDS=${OPS_BACKENDS-"apache-php73"}
declare -x OPS_SERVICES=${OPS_SERVICES-"portainer dashboard mariadb postgres redis adminer"}
declare -x OPS_DOCKER_COMPOSER_IMAGE=${OPS_DOCKER_COMPOSER_IMAGE-"imarcagency/ops-php73:latest"}
declare -x OPS_DOCKER_NODE_IMAGE=${OPS_DOCKER_NODE_IMAGE-"imarcagency/ops-node:$OPS_VERSION"}
declare -x OPS_DOCKER_UTILS_IMAGE=${OPS_DOCKER_UTILS_IMAGE-"imarcagency/ops-utils:$OPS_VERSION"}
declare -x OPS_DOCKER_GID=${OPS_DOCKER_GID-""}
declare -x OPS_DOCKER_UID=${OPS_DOCKER_UID-""}
declare -x OPS_DOCKER_VERSION="18"
declare -x OPS_DOCKER_COMPOSE_VERSION="1.22"
declare -x OPS_DOMAIN=${OPS_DOMAIN-"imarc.io"}
declare -x OPS_MINIO_ACCESS_KEY=${OPS_MINIO_ACCESS_KEY-"minio-access"}
declare -x OPS_MINIO_SECRET_KEY=${OPS_MINIO_SECRET_KEY-"minio-secret"}
declare -x OPS_SITES_DIR=${OPS_SITES_DIR-"$HOME/Sites"}
declare -x OPS_SERVICES_SUBNET=${OPS_SERVICES_SUBNET-"172.23.0.0/16"}
declare -x OPS_ACME_EMAIL=${OPS_ACME_EMAIL-""}
declare -x OPS_ACME_DNS_PROVIDER=${OPS_ACME_DNS_PROVIDER-""}
declare -x OPS_ACME_PRODUCTION=${OPS_ACME_PRODUCTION-"0"}
declare -x OPS_ADMIN_AUTH=${OPS_ADMIN_AUTH-""}
declare -x OPS_ADMIN_AUTH_LABEL_PREFIX=""

declare -x OPS_DEFAULT_BACKEND=${OPS_DEFAULT_BACKEND-"apache-php73"}
declare -x OPS_DEFAULT_DOCROOT=${OPS_DEFAULT_DOCROOT-"public"}
declare -x OPS_DASHBOARD_URL="https://ops.${OPS_DOMAIN}"
declare -x OPS_MKCERT_VERSION="1.3.0"

if [[ ! $OPS_ADMIN_AUTH ]]; then
    OPS_ADMIN_AUTH_LABEL_PREFIX="disabled-"
fi

OPS_ACME_CA_SERVER="https://acme-staging-v02.api.letsencrypt.org/directory"
if [[ $OPS_ACME_PRODUCTION == 1 ]]; then
    OPS_ACME_CA_SERVER="https://acme-v02.api.letsencrypt.org/directory"
fi
declare -rx OPS_ACME_CA_SERVER

# options that can be overridden by a project

declare -x OPS_PROJECT_NAME="$(project-name)"
declare -x OPS_PROJECT_BACKEND="${OPS_DEFAULT_BACKEND}"
declare -x OPS_PROJECT_DOCROOT="${OPS_DEFAULT_DOCROOT}"

# load project config

if [[ -f "$OPS_SITES_DIR/$OPS_PROJECT_NAME/.env" ]]; then
    source "$OPS_SITES_DIR/$OPS_PROJECT_NAME/.env"
fi

declare -x OPS_PROJECT_BASIC_AUTH=""
declare -x OPS_PROJECT_BASIC_AUTH_FILE=".htpasswd"
declare -x OPS_PROJECT_COMPOSE_FILE=${OPS_PROJECT_COMPOSE_FILE-"ops-compose.yml"}
declare -x OPS_PROJECT_TEMPLATE=${OPS_PROJECT_TEMPLATE-""}
declare -x OPS_PROJECT_DB_TYPE="${OPS_PROJECT_DB_TYPE}"
declare -x OPS_PROJECT_DB_NAME="${OPS_PROJECT_DB_NAME-$OPS_PROJECT_NAME}"
declare -x OPS_PROJECT_SYNC_DIRS="${OPS_PROJECT_SYNC_DIRS}"
declare -x OPS_PROJECT_SYNC_NODB="${OPS_PROJECT_SYNC_NODB-0}"
declare -x OPS_PROJECT_SYNC_EXCLUDES="${OPS_PROJECT_SYNC_EXCLUDES}"
declare -x OPS_PROJECT_SYNC_MAXSIZE="${OPS_PROJECT_SYNC_MAXSIZE}"
declare -x OPS_PROJECT_REMOTE_OPS="${OPS_PROJECT_REMOTE_OPS-0}"
declare -x OPS_PROJECT_REMOTE_USER="${OPS_PROJECT_REMOTE_USER}"
declare -x OPS_PROJECT_REMOTE_HOST="${OPS_PROJECT_REMOTE_HOST}"
declare -x OPS_PROJECT_REMOTE_PATH="${OPS_PROJECT_REMOTE_PATH}"
declare -x OPS_PROJECT_REMOTE_DB_HOST="${OPS_PROJECT_REMOTE_DB_HOST}"
declare -x OPS_PROJECT_REMOTE_DB_TYPE="${OPS_PROJECT_REMOTE_DB_TYPE-$OPS_PROJECT_DB_TYPE}"
declare -x OPS_PROJECT_REMOTE_DB_NAME="${OPS_PROJECT_REMOTE_DB_NAME}"
declare -x OPS_PROJECT_REMOTE_DB_USER="${OPS_PROJECT_REMOTE_DB_USER}"
declare -x OPS_PROJECT_REMOTE_DB_PASSWORD="${OPS_PROJECT_REMOTE_DB_PASSWORD}"
declare -x OPS_PROJECT_REMOTE_DB_PORT="${OPS_PROJECT_REMOTE_DB_PORT}"
declare -x OPS_SHELL_BACKEND=${OPS_SHELL_BACKEND-$OPS_PROJECT_BACKEND}
declare -x OPS_SHELL_COMMAND=${OPS_SHELL_COMMAND-"bash"}
declare -x OPS_SHELL_USER=${OPS_SHELL_USER-"www-data"}

# load custom commands

if [[ -f "$OPS_SITES_DIR/$OPS_PROJECT_NAME/ops-commands.sh" ]]; then
    source "$OPS_SITES_DIR/$OPS_PROJECT_NAME/ops-commands.sh"
fi

main "$@"
