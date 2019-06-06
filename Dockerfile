FROM debian:buster

MAINTAINER Imarc <info@imarc.com>

RUN apt-get update && apt-get install -y --fix-missing \
    apt-transport-https \
    autoconf \
    build-essential \
    ca-certificates \
    chrpath \
    curl \
    dnsutils \
    g++ \
    git-core \
    gnupg2 \
    iproute2 \
    libssl-dev \
    net-tools \
    netcat \
    openssl \
    pkg-config \
    python \
    rsync \
    software-properties-common \
    sudo \
    vim \
    wget

RUN curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
RUN add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/debian \
   $(lsb_release -cs) \
   stable"

RUN curl -sL https://deb.nodesource.com/setup_10.x -o nodesource_setup.sh
RUN bash nodesource_setup.sh


RUN apt-get update && apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    nodejs

RUN sudo systemctl disable docker

# install docker-compose
RUN curl -L https://github.com/docker/compose/releases/download/1.24.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
RUN chmod +x /usr/local/bin/docker-compose

RUN mkdir /ops && chmod 775 /ops

RUN useradd -U -m -u 1000 -G root ops

RUN mkdir -p /home/ops/Sites && chown ops:ops /home/ops/Sites

COPY . /usr/local/src/ops

RUN echo '%ops ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/ops

RUN chmod 777 /usr/lib/node_modules
RUN chmod 777 /usr/bin

RUN touch /var/run/docker.sock && chown ops:ops /var/run/docker.sock

ENV OPS_HOME /home/ops/.ops
ENV OPS_SITES_DIR /home/ops/Sites

USER ops

RUN npm install -g /usr/local/src/ops

ENTRYPOINT ops

