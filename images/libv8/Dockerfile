FROM debian:stretch

MAINTAINER Imarc <info@imarc.com>

# install supporting packages
RUN apt-get update && apt-get install -y --fix-missing \
    apt-transport-https \
    autoconf \
    build-essential \
    chrpath \
    g++ \
    patchelf \
    libglib2.0-0 \
    libglib2.0-dev \
    git-core \
    gnupg \
    pkg-config \
    python2.7 \
    bzip2 \
    xz-utils

WORKDIR /tmp

#RUN git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git && \
#    export PATH=`pwd`/depot_tools:"$PATH" && \
#    fetch v8 && \
#    cd v8 && \
#    git checkout lkgr && \
#    gclient sync && \
#    gn gen out.gn/library --args='is_debug=false is_component_build=true v8_enable_i18n_support=false' && \
#    ninja -C out.gn/library libv8.so

#cp include/*.h /usr/local/include
#cp out.gn/library/*.so /usr/local/lib

RUN ln -s /usr/bin/python2.7 /usr/bin/python

RUN git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git /tmp/depot_tools && \
    export PATH="$PATH:/tmp/depot_tools" && \
    cd /usr/local/src && \
    fetch v8 && \
    cd v8 && \
    git checkout 6.9.427.18 && \
    gclient sync && \
    tools/dev/v8gen.py -vv x64.release -- is_component_build=true && \
    ninja -C out.gn/x64.release/ && \
    mkdir -p /opt/v8/lib /opt/v8/include && \
    cp out.gn/x64.release/lib*.so out.gn/x64.release/*_blob.bin out.gn/x64.release/icudtl.dat /opt/v8/lib/ && \
    cp -R include/* /opt/v8/include/ && \
    for A in /opt/v8/lib/*.so; do patchelf --set-rpath '$ORIGIN' $A; done

    # Fetch & Build V8js
    #git clone --branch 2.1.0 --depth 1 https://github.com/phpv8/v8js.git /usr/local/src/v8js && \
    #cd /usr/local/src/v8js && \
    #phpize && ./configure --with-v8js=/opt/v8 LDFLAGS="-lstdc++" && \
    #export NO_INTERACTION=1 && make && make install && \
    #echo extension=v8js.so > /etc/php/7.2/cli/conf.d/99-v8js.ini && \
    ## Cleanup
    #rm -rf /tmp/depot_tools /usr/local/src/v8 /usr/local/src/v8js && \
    #apt-get remove -y php7.2-dev build-essential python2.7 patchelf lsb-release libglib2.0-dev bzip2 xz-utils && \
    #apt-get autoremove -y && apt-get clean && \
    #rm -rf /var/lib/apt/lists/*
