ARG PHP_VERSION=8.2
FROM php:${PHP_VERSION}-fpm

# Common system deps
RUN set -eux;     apt-get update;     apt-get install -y --no-install-recommends       git unzip curl ca-certificates       libzip-dev libicu-dev       libonig-dev libxml2-dev       default-mysql-client;     docker-php-ext-install -j"$(nproc)"       pdo pdo_mysql intl zip opcache;     # Redis (PECL) is best-effort: PHP nightly/edge versions (e.g. 8.5) may fail to compile.
    if pecl install redis; then       docker-php-ext-enable redis;     else       echo "NOTE: PECL redis failed for PHP ${PHP_VERSION}. Continuing without redis extension.";     fi;     rm -rf /var/lib/apt/lists/*

# Composer (works across PHP versions)
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/projects
