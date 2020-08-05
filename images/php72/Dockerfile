FROM php:7.2.20-apache-stretch

MAINTAINER Imarc <info@imarc.com>

# fix for postgresql-client
RUN mkdir -p /usr/share/man/man1 && \
    mkdir -p /usr/share/man/man7

# install supporting packages
RUN apt-get update && apt-get install -y --fix-missing \
    apt-transport-https \
    autoconf \
    build-essential \
    chrpath \
    curl \
    dnsutils \
    freetds-dev \
    g++ \
    git-core \
    gnupg \
    imagemagick \
    libcurl4-openssl-dev \
    libdbd-freetds \
    libjpeg62-turbo-dev \
    libldap2-dev \
    libmagickwand-dev \
    libmcrypt-dev \
    libmemcached-dev \
    libmemcached11 \
    libpng-dev \
    libpq-dev \
    libpspell-dev \
    libsqlite3-dev \
    mysql-client \
    netcat \
    pkg-config \
    postgresql-client \
    python \
    subversion \
    unixodbc-dev \
    vim \
    wget

# link libsysbdb libs. (required for sqlsrv extension)
RUN ln -s /usr/lib/x86_64-linux-gnu/libsybdb.so /usr/lib/libsybdb.so
RUN ln -s /usr/lib/x86_64-linux-gnu/libsybdb.a /usr/lib/libsybdb.a

# Configure GD with jpeg
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/

# Configure LDAP
RUN docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/

# install officially supported php extensions
RUN docker-php-ext-install \
    bcmath \
    curl \
    gd \
    iconv \
    ldap \
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
    macro \
    http2 \
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
