FROM php:8.2-apache

# =========================
# System dependencies
# =========================
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    curl \
    libzip-dev \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    && docker-php-ext-install \
        pdo \
        pdo_mysql \
        mbstring \
        exif \
        pcntl \
        bcmath \
        gd \
        zip \
    && rm -rf /var/lib/apt/lists/*

# =========================
# Apache setup for Laravel
# =========================
RUN a2enmod rewrite

RUN sed -i 's|/var/www/html|/var/www/html/public|g' \
    /etc/apache2/sites-available/000-default.conf

# =========================
# Composer
# =========================
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# =========================
# App setup
# =========================
WORKDIR /var/www/html

COPY . .

# =========================
# Install dependencies (PROD ONLY)
# =========================
RUN composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist

# =========================
# Permissions baseline (IMPORTANT for K8s)
# NOTE: final ownership will still depend on volume mounts
# =========================
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 /var/www/html/storage \
    && chmod -R 775 /var/www/html/bootstrap/cache

# =========================
# Laravel optimization (safe)
# =========================
RUN php artisan config:clear || true \
    && php artisan cache:clear || true

# =========================
# Expose Apache
# =========================
EXPOSE 80

CMD ["apache2-foreground"]