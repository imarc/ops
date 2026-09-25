FROM alpine:3.24

LABEL maintainer="Imarc <info@imarc.com>"

RUN apk add --update --no-cache \
        bash \
        curl \
        docker \
        docker-cli-compose \
        git \
        jq \
        openssh \
        openssl \
        socat \
        rsync \
        nodejs \
        npm \
        netcat-openbsd \
        py3-pip \
        unzip \
        wget \
        apache2 \
        yq-go \
        && rm -rf /var/cache/apk/*

# keep the standalone docker-compose command, backed by the compose v2 plugin
RUN ln -s /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose

# install npm dependencies
#RUN npm install broken-link-checker -g
RUN npm install -g localtunnel
