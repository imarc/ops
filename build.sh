#!/bin/bash

set -e

OPS_VERSION=$(jq -r .version package.json)
echo -n $OPS_VERSION > VERSION

PLATFORMS="linux/amd64,linux/arm64"

docker buildx build --platform=$PLATFORMS -t "imarcagency/ops-apache-php72:$OPS_VERSION" images/php72 --push
docker buildx build --platform=$PLATFORMS -t "imarcagency/ops-apache-php73:$OPS_VERSION" images/php73 --push
docker buildx build --platform=$PLATFORMS -t "imarcagency/ops-apache-php74:$OPS_VERSION" images/php74 --push
docker buildx build --platform=$PLATFORMS -t "imarcagency/ops-apache-php80:$OPS_VERSION" images/php80 --push
docker buildx build --platform=$PLATFORMS -t "imarcagency/ops-apache-php81:$OPS_VERSION" images/php81 --push
docker buildx build --platform=$PLATFORMS -t "imarcagency/ops-apache-php82:$OPS_VERSION" images/php82 --push
docker buildx build --platform=$PLATFORMS -t "imarcagency/ops-apache-php83:$OPS_VERSION" images/php83 --push
docker buildx build --platform=$PLATFORMS -t "imarcagency/ops-node:$OPS_VERSION" images/node --push
docker buildx build --platform=$PLATFORMS -t "imarcagency/ops-utils:$OPS_VERSION" images/utils --push
docker buildx build --platform=$PLATFORMS -t "imarcagency/ops:$OPS_VERSION" . --push
