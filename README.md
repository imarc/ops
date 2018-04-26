# Ops

**Version 0.4.5**

- A local isolated environment focused on PHP development
- Zero-config host creation: make a folder.
- Zero-config self-signed certs for local HTTPS.
- Shared services out of the box: MariaDB, PostgreSQL, Redis, Mailhog, Adminer, and more.
- Built on Docker and Traefik. Add ad-hoc services as needed.

![Ops Dashboard](dashboard.png)

## Prerequisites

Ops supports Linux, Mac, and Windows Subshell Linux (WSL)

bash, docker, and docker-compose are required.

### Linux Installation Instructions

- [Install Docker CE](https://docs.docker.com/engine/installation/linux/)

### Mac Installation Instructions

- [Install Docker for Mac](https://docs.docker.com/docker-for-mac/install/)

### Windows Subshell for Linux

- [Install Docker for Windows](https://docs.docker.com/docker-for-windows/install/)
- [Install Docker Client](https://medium.com/@sebagomez/installing-the-docker-client-on-ubuntus-windows-subsystem-for-linux-612b392a44c4)

## Install

Install with npm:

    npm install -g git+ssh://git@gitlab.imarc.net:imarc/ops.git

## Basics

The first time you run ops, you will go through the install process. **You will
also be asked for your password so ops can install the certs for HTTPS support**

Start ops services:

    ops start


Go to the Dashboard ([https://ops.imarc.io](https://ops.imarc.io)) in your browser.

To mount a new project, all you need to do is create a directory within $HOME/Sites.
The directory name can only contain letters, numbers, and dashes. Your project will then
be available at https://DIRECTORYNAME.imarc.io

The web server will look for one of the following project directories to use as
a document root: `public`, `web`, `public_html`, `htdocs`, or `docroot`. The
project root directory will be used if no document root is found.


To stop ops:

    ops stop

## Services

You can connect your app to the following shared services:

**MariaDB 10.3**<br>
hostname: mariadb<br>
username: root<br>
password: *none*<br>
port: 3306

**PostgreSQL 9.6**<br>
hostname: postgres<br>
username: postgres<br>
password: *none*<br>
port: 5432

**Redis 3.2**<br>
hostname: redis<br>
port: 6379

**Memcached 1.4**<br>
hostname: memcached<br>
port: 11211

**Minio**<br>
hostname: minio<br>
access key: minio-access<br>
secret key: minio-secret<br>

**Mailhog**<br>
*SMTP Config:*<br>
hostname: mailhog<br>
port: 1025

## Custom Project Container

*This is for advanced users and it would be best to have a solid understanding of docker and docker-compose files
before moving forward with implementing this solution*

There are times where you want to configura a custom container to run your project. This could be due to:

- You need a PHP configuration/extension
- You need to lock down the PHP version, or use a specific image.
- You are using a language that isn't PHP

With a little configuration, Ops allows you to run a custom container beside the shared services. Ops' `project`
subcommands deal with project specific compose commands. Running `ops project start` within a project directory
will load a `docker-compose.ops.yml` file. The compose files that are loaded can be
configured with the `OPS_COMPOSE_FILE` option.

Here is generic docker-compose.ops.yml file:

    version: '2'

    services:
      craft:
        image: imarcagency/php-apache:2

        labels:
          - "ops.linked=true"
          - "traefik.enable=true"
          - "traefik.docker.network=ops_gateway"
          - "traefik.frontend.rule=Host:${OPS_PROJECT_NAME}.${OPS_DOMAIN}"
          - "traefik.port=80"
        environment:
          - "APACHE_UID=${OPS_DOCKER_UID}"
          - "APACHE_GID=${OPS_DOCKER_GID}"
          - "APACHE_ROOT=/var/www/public"
        volumes:
          - "./:/var/www/:cached"
        networks:
          - default
          - ops_gateway
          - ops_backend

    networks:
      ops_gateway:
        external: true
      ops_backend:
        external: true
        
The most important things are the labes and the networks. 
Those settings are required for the proxy to function or for your app to conenct to shared services.
Everything else can be customized to whatever your app requires.



## Contributing

If you are developing ops itself, debugging, or want to try out bleeding edge features, It is recommended you install like so:

    # clone into a local dir and enter dir
    git clone git@gitlab.imarc.net:imarc/ops.git
    cd ops

    # create 'ops' symlink to your repo
    npm install -g .

Installing like this means your global ops script will point directly to the repo and you can make changes on the fly.

## License

MIT License

Copyright (c) 2018 Imarc
