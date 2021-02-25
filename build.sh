#!/bin/bash

set -e

OPS_VERSION=$(jq -r .version package.json)
echo -n $OPS_VERSION > VERSION

docker build --no-cache -t "imarcagency/ops-apache-php72:$OPS_VERSION" images/php72
docker build --no-cache -t "imarcagency/ops-apache-php73:$OPS_VERSION" images/php73
docker build --no-cache -t "imarcagency/ops-apache-php74:$OPS_VERSION" images/php74
docker build --no-cache -t "imarcagency/ops-apache-php80:$OPS_VERSION" images/php80
docker build --no-cache -t "imarcagency/ops-node:$OPS_VERSION" images/node
docker build --no-cache -t "imarcagency/ops-utils:$OPS_VERSION" images/utils
docker build --no-cache -t "imarcagency/ops:$OPS_VERSION" .
