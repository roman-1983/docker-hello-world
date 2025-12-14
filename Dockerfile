# syntax=docker/dockerfile:1

############################
# Composer build stage
############################
FROM composer:2 AS vendor

WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install \
    --no-dev \
    --prefer-dist \
    --no-interaction \
    --optimize-autoloader

############################
# FrankenPHP runtime
############################
FROM dunglas/frankenphp:1

WORKDIR /app

RUN install-php-extensions pdo_pgsql opcache

COPY . /app
COPY --from=vendor /app/vendor /app/vendor
COPY Caddyfile /etc/caddy/Caddyfile

ENV APP_ENV=prod

RUN php bin/console cache:clear \
 && php bin/console cache:warmup \
 && chown -R www-data:www-data /app/var

EXPOSE 80
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

CMD ["/usr/local/bin/entrypoint.sh"]
