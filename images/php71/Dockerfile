FROM php:7.1.20-apache-stretch

MAINTAINER Imarc <info@imarc.com>

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
    libpspell-dev \
    libsqlite3-dev \
    netcat \
    pkg-config \
    python \
    subversion \
    unixodbc-dev \
    vim \
    wget

# link libsysbdb libs. (required for sqlsrv extension)
RUN ln -s /usr/lib/x86_64-linux-gnu/libsybdb.so /usr/lib/libsybdb.so
RUN ln -s /usr/lib/x86_64-linux-gnu/libsybdb.a /usr/lib/libsybdb.a

# install officially supported php extensions
RUN docker-php-ext-install \
    curl \
    gd \
    iconv \
    mcrypt \
    mysqli \
    opcache \
    pcntl \
    pdo \
    pdo_dblib \
    pdo_mysql \
    pdo_pgsql \
    pdo_sqlite \
    pgsql \
    pspell \
    soap \
    zip

# install redis / xdebug extensions
RUN pecl install \
    imagick \
    memcached \
    pdo_sqlsrv \
    redis \
    sqlsrv \
    xdebug

RUN docker-php-ext-enable \
    imagick \
    memcached \
    pdo_sqlsrv \
    redis \
    sqlsrv \
    xdebug

# cleanup apt
RUN apt-get clean
RUN apt-get autoremove -y
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/src/*

# install composer
WORKDIR /tmp
RUN wget https://getcomposer.org/composer.phar
RUN mv composer.phar /bin/composer
RUN chmod 755 /bin/composer

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
