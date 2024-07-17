#!/bin/sh

################################################################################
#
# DEPRECATION NOTICE
#
# This file should still work for building images locally, however the official
# builds of imarc/ops docker images is now been moved to a CI/CD pipeline.
#
################################################################################

set -e

if [ -z $OPS_VERSION ]; then
    OPS_VERSION=$(jq -r .version package.json)
fi

PLATFORM="${PLATFORM-linux/amd64,linux/arm64,linux/arm64/v8}"

echo "Building docker images for $PLATFORM and ops version $OPS_VERSION..."

echo -n $OPS_VERSION > VERSION

docker buildx build --platform=$PLATFORM -t "imarcagency/ops-apache-php72:$OPS_VERSION" images/php72 --progress=plain --push
docker buildx build --platform=$PLATFORM -t "imarcagency/ops-apache-php73:$OPS_VERSION" images/php73 --progress=plain --push
docker buildx build --platform=$PLATFORM -t "imarcagency/ops-apache-php74:$OPS_VERSION" images/php74 --progress=plain --push
docker buildx build --platform=$PLATFORM -t "imarcagency/ops-apache-php80:$OPS_VERSION" images/php80 --progress=plain --push
docker buildx build --platform=$PLATFORM -t "imarcagency/ops-apache-php81:$OPS_VERSION" images/php81 --progress=plain --push
docker buildx build --platform=$PLATFORM -t "imarcagency/ops-apache-php82:$OPS_VERSION" images/php82 --progress=plain --push
docker buildx build --platform=$PLATFORM -t "imarcagency/ops-apache-php83:$OPS_VERSION" images/php83 --progress=plain --push
docker buildx build --platform=$PLATFORM -t "imarcagency/ops-node:$OPS_VERSION" images/node --push
docker buildx build --platform=$PLATFORM -t "imarcagency/ops-utils:$OPS_VERSION" images/utils --push

echo "Complete."
