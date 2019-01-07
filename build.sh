#!/bin/bash

set -e

OPS_VERSION=$(jq -r .version package.json)

echo -n $OPS_VERSION > VERSION

docker build -t "imarcagency/ops-apache-php56:$OPS_VERSION" images/php56
docker build -t "imarcagency/ops-apache-php71:$OPS_VERSION" images/php71
docker build -t "imarcagency/ops-apache-php72:$OPS_VERSION" images/php72
docker build -t "imarcagency/ops-apache-php73:$OPS_VERSION" images/php73
docker build -t "imarcagency/ops-node:$OPS_VERSION" images/node
docker build -t "imarcagency/ops-utils:$OPS_VERSION" images/utils

docker push imarcagency/ops-apache-php56:$OPS_VERSION
docker push imarcagency/ops-apache-php71:$OPS_VERSION
docker push imarcagency/ops-apache-php72:$OPS_VERSION
docker push imarcagency/ops-apache-php73:$OPS_VERSION
docker push imarcagency/ops-node:$OPS_VERSION
docker push imarcagency/ops-utils:$OPS_VERSION
