FROM --platform=$BUILDPLATFORM php:7.3.33-apache-bullseye AS base

LABEL AUTHOR "Imarc <info@imarc.com>"

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
    iproute2 \
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
    libwebp-dev \
    libzip-dev \
    default-mysql-client \
    netcat \
    net-tools \
    pkg-config \
    postgresql-client \
    python \
    unixodbc-dev \
    vim \
    wget

RUN curl -sSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft.gpg
RUN ARCH=$(dpkg --print-architecture) && echo "deb [arch=${ARCH} signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/debian/11/prod bullseye main" > /etc/apt/sources.list.d/mssql-release.list

RUN apt-get update
RUN ACCEPT_EULA=y apt-get install -y \
    msodbcsql18 \
    mssql-tools18

# link libsysbdb libs. (required for sqlsrv extension)
RUN ln -s /usr/lib/x86_64-linux-gnu/libsybdb.so /usr/lib/libsybdb.so
RUN ln -s /usr/lib/x86_64-linux-gnu/libsybdb.a /usr/lib/libsybdb.a

# Configure GD with jpeg and webp
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-webp-dir=/usr/include/


# AMD64 stage
FROM base AS build-amd64

# Configure LDAP
RUN docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/

# Configure DBLib
RUN docker-php-ext-configure pdo_dblib --with-libdir=lib/x86_64-linux-gnu/


# ARM64 stage
FROM base AS build-arm64

# Configure LDAP
RUN docker-php-ext-configure ldap --with-libdir=lib/aarch64-linux-gnu/

# Configure DBLib
RUN docker-php-ext-configure pdo_dblib --with-libdir=lib/aarch64-linux-gnu/



FROM build-${TARGETARCH} AS final

# Enable Exif
RUN docker-php-ext-configure exif --enable-exif


# install officially supported php extensions
RUN docker-php-ext-install \
    bcmath \
    curl \
    exif \
    gd \
    iconv \
    intl \
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

# install pecl extensions
RUN pecl channel-update pecl.php.net

RUN pecl install \
    imagick \
    memcached \
    redis-5.3.7 \
    xdebug-3.1.6 \
    sqlsrv-5.9.0 \
    pdo_sqlsrv-5.9.0

# enable pecl extensions
RUN docker-php-ext-enable \
    imagick \
    memcached \
    exif \
    redis \
    xdebug \
    sqlsrv \
    pdo_sqlsrv

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
    include \
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
