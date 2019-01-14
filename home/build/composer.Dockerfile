FROM composer:1.7 as composer

COPY composer.json composer.json
COPY composer.lock composer.lock

RUN composer install \
    --ignore-platform-reqs \
    --no-interaction \
    --no-plugins \
    --no-scripts \
    --prefer-dist

COPY --from=composer /app/vendor/ /var/www/html/vendor/

