FROM node:8.11 as laravel-mix

ARG OPS_PROJECT_DOCROOT

RUN mkdir -p /app/public

COPY package.json webpack.mix.js package-lock.json /app/
COPY resources/assets/ /app/resources/assets/

WORKDIR /app

RUN npm install && npm run prod

COPY --from=laravel-mix /app/${OPS_PROJECT_DOCROOT}/js/ /var/www/html/${OPS_PROJECT_DOCROOT}/js/
COPY --from=laravel-mix /app/${OPS_PROJECT_DOCROOT}/css/ /var/www/html/${OPS_PROJECT_DOCROOT}/css/
COPY --from=laravel-mix /app/${OPS_PROJECT_DOCROOT}/mix-manifest.json /var/www/html/mix-manifest.json
