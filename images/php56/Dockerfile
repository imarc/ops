FROM php:5.6.37-apache-stretch

# install supporting packages
RUN apt-get update && apt-get install -y --fix-missing \
    autoconf \
    build-essential \
    chrpath \
    curl \
    freetds-dev \
    g++ \
    git-core \
    imagemagick \
    libcurl4-openssl-dev \
    libdbd-freetds \
    libgmp-dev \
    libjpeg62-turbo-dev \
    libmagickwand-dev \
    libmcrypt-dev \
    libmcrypt-dev \
    libmemcached-dev \
    libmemcached11 \
    libmhash-dev \
    libpng-dev \
    libpq-dev \
    libpspell-dev \
    libsqlite3-dev \
    libssl-dev \
    libtidy-dev \
    libxslt1-dev \
    netcat \
    pkg-config \
    python \
    re2c \
    sudo \
    vim \
    wget



# link libsysbdb libs. (required for mssql extension)
RUN ln -s /usr/lib/x86_64-linux-gnu/libsybdb.so /usr/lib/libsybdb.so
RUN ln -s /usr/lib/x86_64-linux-gnu/libsybdb.a /usr/lib/libsybdb.a

# link gmp.h for gmp extension
RUN ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/local/include/

# install officially supported php extensions
RUN docker-php-ext-install \
    bz2 \
    calendar \
    ctype \
    curl \
    dom \
    exif \
    fileinfo \
    ftp \
    gettext \
    gd \
    gmp \
    hash \
    iconv \
    json \
    mbstring \
    mcrypt \
    mssql \
    mysql \
    mysqli \
    opcache \
    pcntl \
    pdo \
    pdo_dblib \
    pdo_mysql \
    pdo_pgsql \
    pdo_sqlite \
    posix \
    pspell \
    pgsql \
    session \
    shmop \
    simplexml \
    soap \
    sockets \
    sysvmsg \
    sysvsem \
    sysvshm \
    tidy \
    tokenizer \
    wddx \
    xml \
    xmlreader \
    xmlwriter \
    xsl

RUN pecl install \
    imagick \
    memcached-2.2.0 \
    redis \
    xdebug-2.5.5
#
RUN docker-php-ext-enable \
    imagick \
    memcached \
    redis \
    xdebug

# cleanup apt
RUN apt-get clean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/src/*

# install composer
RUN wget https://getcomposer.org/composer.phar && \
    mv composer.phar /usr/local/bin/composer && \
    chmod 755 /usr/local/bin/composer

# enable apache modules
RUN a2enmod \
    cache \
    cache_disk \
    expires \
    headers \
    lua \
    rewrite \
    vhost_alias

# copy php.ini
COPY php.ini /usr/local/etc/php/conf.d

# copy apache config
COPY 000-default.conf /etc/apache2/sites-enabled/000-default.conf

# set working directory
WORKDIR /var/www

# entrypoint/command
COPY docker-entrypoint /usr/local/bin/
RUN chmod 755 /usr/local/bin/docker-entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]
CMD ["apache2-foreground"]
