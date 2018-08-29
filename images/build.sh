#!/bin/bash

set -e

OPS_VERSION=$(cat ../package.json | awk '/"version":/ { gsub(/[",]/, ""); print $2 }')

docker build -t "imarcagency/ops-apache-php56:$OPS_VERSION" php56
docker build -t "imarcagency/ops-apache-php71:$OPS_VERSION" php71
docker build -t "imarcagency/ops-apache-php72:$OPS_VERSION" php72

docker push imarcagency/ops-apache-php56:$OPS_VERSION
docker push imarcagency/ops-apache-php71:$OPS_VERSION
docker push imarcagency/ops-apache-php72:$OPS_VERSION

