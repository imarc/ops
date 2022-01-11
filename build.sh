#!/bin/bash

set -e

OPS_VERSION=$(jq -r .version package.json)
echo -n $OPS_VERSION > VERSION

docker build -t "imarcagency/ops-apache-php72:$OPS_VERSION" images/php72
docker build -t "imarcagency/ops-apache-php73:$OPS_VERSION" images/php73
docker build -t "imarcagency/ops-apache-php74:$OPS_VERSION" images/php74
docker build -t "imarcagency/ops-apache-php80:$OPS_VERSION" images/php80
docker build -t "imarcagency/ops-apache-php81:$OPS_VERSION" images/php81
docker build -t "imarcagency/ops-node:$OPS_VERSION" images/node
docker build -t "imarcagency/ops-utils:$OPS_VERSION" images/utils
docker build -t "imarcagency/ops:$OPS_VERSION" .
