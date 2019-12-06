#!/bin/bash

set -e

OPS_VERSION=$(jq -r .version package.json)
echo -n $OPS_VERSION > VERSION

#docker build -t "imarcagency/ops-debian-stretch-libv8:$OPS_VERSION" images/libv8
docker build -t "imarcagency/ops-apache-php71:$OPS_VERSION" images/php71
docker build -t "imarcagency/ops-apache-php72:$OPS_VERSION" images/php72
docker build -t "imarcagency/ops-apache-php73:$OPS_VERSION" images/php73
docker build -t "imarcagency/ops-node:$OPS_VERSION" images/node
docker build -t "imarcagency/ops-utils:$OPS_VERSION" images/utils
docker build -t "imarcagency/ops:$OPS_VERSION" .
