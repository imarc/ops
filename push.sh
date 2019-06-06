#!/bin/bash

set -e

OPS_VERSION=$(jq -r .version package.json)

docker push imarcagency/ops-apache-php56:$OPS_VERSION
docker push imarcagency/ops-apache-php71:$OPS_VERSION
docker push imarcagency/ops-apache-php72:$OPS_VERSION
docker push imarcagency/ops-apache-php73:$OPS_VERSION
docker push imarcagency/ops-node:$OPS_VERSION
docker push imarcagency/ops-utils:$OPS_VERSION
docker push imarcagency/ops:$OPS_VERSION
