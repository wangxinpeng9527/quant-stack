FROM php:8.3-cli-alpine

# 必要依赖（用于编译 pecl 扩展）
RUN apk add --no-cache \
    bash git curl zip unzip \
    linux-headers \
    $PHPIZE_DEPS

# ✅ 安装 redis 扩展
RUN pecl install redis \
  && docker-php-ext-enable redis

# 安装你需要的 PHP 扩展
RUN docker-php-ext-install pcntl pdo_mysql

# composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/interaction
