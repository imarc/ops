#!/bin/bash

set -e

V8_VERSION=4.10.50
V8JS_VERSION=1.1.0

# install dependencies
export DEBIAN_FRONTEND="noninteractive"
apt-get update
apt-get -y install --no-install-recommends git subversion make g++ python curl chrpath

# depot tools
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git /usr/local/depot_tools
export PATH=$PATH:/usr/local/depot_tools

# download v8
cd /usr/local/src
fetch v8

# compile v8
cd /usr/local/src/v8
git checkout $V8_VERSION
make native library=shared snapshot=off -j4

# install v8
mkdir -p /usr/local/lib
cp /usr/local/src/v8/out/native/lib.target/lib*.so /usr/local/lib
cat <<EOF | ar -M
create /usr/local/lib/libv8_libplatform.a
addlib /usr/local/src/v8/out/native/obj.target/tools/gyp/libv8_libplatform.a
save
end
EOF
cp -R /usr/local/src/v8/include /usr/local
chrpath -r '$ORIGIN' /usr/local/lib/libv8.so

# get v8js, compile and install
cd /usr/local/src
curl -LO https://github.com/phpv8/v8js/releases/download/${V8JS_VERSION}/v8js-${V8JS_VERSION}.tgz
tar xzf v8js-${V8JS_VERSION}.tgz
cd v8js-${V8JS_VERSION}
phpize
./configure --with-v8js=/usr/local
export NO_INTERACTION=1
make all test install

# add module configuration
cat <<EOF > /etc/php/mods-available/v8js.ini
; configuration for php v8js module
; priority=20
extension=v8js.so
EOF

# enable extension
# phpenmod -v 7.0 -s ALL v8js

rm -rf /root/.cache /var/lib/apt/lists/* /usr/local/src/* /usr/local/depot_tools
