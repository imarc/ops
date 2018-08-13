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
    libjpeg62-turbo-dev \
    libmagickwand-dev \
    libmcrypt-dev \
    libmemcached-dev \
    libmemcached11 \
    libpng-dev \
    libpq-dev \
    libsqlite3-dev \
    libtidy-dev \
    netcat \
    pkg-config \
    python \
    sudo \
    vim \
    wget


# link libsysbdb libs. (required for mssql extension)
RUN ln -s /usr/lib/x86_64-linux-gnu/libsybdb.so /usr/lib/libsybdb.so
RUN ln -s /usr/lib/x86_64-linux-gnu/libsybdb.a /usr/lib/libsybdb.a

# install officially supported php extensions
RUN docker-php-ext-install \
    curl \
    gd \
    iconv \
    mcrypt \
    mssql \
    mysql \
    mysqli \
    opcache \
    pdo \
    pdo_dblib \
    pdo_mysql \
    pdo_pgsql \
    pdo_sqlite \
    pgsql \
    soap \
    tidy \
    zip

RUN pecl install \
    imagick \
    memcached-2.2.0 \
    redis \
    xdebug-2.5.5

RUN docker-php-ext-enable \
    imagick \
    memcached \
    redis \
    xdebug

# cleanup apt
RUN apt-get clean
RUN apt-get autoremove -y
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/src/*

# install composer
RUN wget https://getcomposer.org/composer.phar
RUN mv composer.phar /usr/local/bin/composer
RUN chmod 755 /usr/local/bin/composer

## enable apache modules
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
