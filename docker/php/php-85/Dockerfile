FROM php:8.5-fpm

# Install extensions via mlocati/docker-php-extension-installer
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

# Attempting standard set. Note: 8.5 might have limited PECL support.
# If redis fails here, the installer usually tries to build from source.
RUN install-php-extensions \
    bcmath \
    exif \
    gd \
    intl \
    mysqli \
    opcache \
    pdo_mysql \
    zip

# Common system tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    unzip \
    curl \
    default-mysql-client \
    && rm -rf /var/lib/apt/lists/*

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/projects
