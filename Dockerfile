FROM php:8.2-apache

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    libicu-dev \
    libzip-dev \
    zlib1g-dev \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libxml2-dev \
    libcurl4-openssl-dev \
    libonig-dev \
    libsodium-dev \
    ca-certificates \
    unzip \
    git \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" \
    mysqli \
    pdo_mysql \
    intl \
    zip \
    gd \
    soap \
    exif \
    opcache \
    mbstring \
    xml \
    curl \
    sodium \
    && (a2dismod mpm_event || true) \
    && (a2dismod mpm_worker || true) \
    && a2enmod mpm_prefork rewrite headers expires \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html

COPY . /var/www/html
COPY docker/entrypoint.sh /usr/local/bin/moodle-entrypoint

RUN chmod +x /usr/local/bin/moodle-entrypoint \
    && mkdir -p /var/moodledata \
    && chown -R www-data:www-data /var/moodledata /var/www/html

EXPOSE 80

ENTRYPOINT ["moodle-entrypoint"]
CMD ["apache2-foreground"]
