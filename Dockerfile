# syntax=docker/dockerfile:1

FROM composer:2 AS vendor
WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install \
    --no-dev \
    --prefer-dist \
    --no-interaction \
    --optimize-autoloader

FROM dunglas/frankenphp:1
WORKDIR /app

RUN install-php-extensions pdo_pgsql opcache

# erst Konfig rein (ändert seltener)
COPY Caddyfile /etc/caddy/Caddyfile
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# dann App-Code
COPY . /app
COPY --from=vendor /app/vendor /app/vendor

ENV APP_ENV=prod

# kein cache warmup hier erzwingen; macht dein Entrypoint sowieso sauber zur Runtime
RUN chown -R www-data:www-data /app/var

EXPOSE 80
CMD ["/usr/local/bin/entrypoint.sh"]
