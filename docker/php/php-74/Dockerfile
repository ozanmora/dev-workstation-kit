FROM php:7.4-fpm

# Install extensions via mlocati/docker-php-extension-installer
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

RUN install-php-extensions \
    bcmath \
    exif \
    gd \
    intl \
    mysqli \
    opcache \
    pdo_mysql \
    zip \
    redis \
    memcached

# Common system tools (git, unzip, etc. are still nice to have for composer/debugging)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    unzip \
    curl \
    default-mysql-client \
    && rm -rf /var/lib/apt/lists/*

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/projects
