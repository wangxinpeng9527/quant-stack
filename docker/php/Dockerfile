FROM php:8.3-fpm-alpine

# ======================
# System deps（含 pecl 编译）
# ======================
RUN apk add --no-cache \
  bash git curl zip unzip \
  icu-dev oniguruma-dev libzip-dev \
  mysql-client \
  linux-headers \
  $PHPIZE_DEPS

# ======================
# PHP extensions
# ======================
RUN pecl install redis \
  && docker-php-ext-enable redis \
  && docker-php-ext-install \
      pdo_mysql \
      mbstring \
      zip \
      intl \
      opcache

# ======================
# Composer
# ======================
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/backend
