# Ops CLI

**Version 0.3.1**

- A dead-simple local & secure PHP development environment w/tooling
- Traefik proxy automatic HTTPS and dynamic per-project docker services
- Quick initialization of projects from templates (WIP)
- Ability to package an application for production deployment (WIP)

## Prerequisites

Ops supports Linux, Mac, and Windows Subshell Linux (WSL)

bash, docker, docker-compose, are required.

**See resources section for more prerequisite installation instructions**

## Install

    # install package with npm
    npm install -g git+ssh://git@gitlab.imarc.net:imarc/ops.git

    # run install script.
    ops system install

## Resources

### Linux Installation Instructions

- [Install Docker CE](https://docs.docker.com/engine/installation/linux/)

### Mac Installation Instructions

- [Install Docker for Mac](https://docs.docker.com/docker-for-mac/install/)

### Windows Subshell for Linux

- [Install Docker for Windows](https://docs.docker.com/docker-for-windows/install/)
- [Install Docker Client](https://medium.com/@sebagomez/installing-the-docker-client-on-ubuntus-windows-subsystem-for-linux-612b392a44c4)


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
