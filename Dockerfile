# syntax=docker/dockerfile:1

########################################
# Stage 1 — Build front-end assets (Vite + Tailwind 4)
########################################
FROM node:22-bookworm-slim AS frontend

WORKDIR /app

# Only the files needed to build assets (better layer caching)
COPY package.json vite.config.js ./
COPY resources ./resources

RUN npm install --no-audit --no-fund \
 && npm run build

########################################
# Stage 2 — PHP application runtime (Laravel 13 requires PHP >= 8.4.1)
########################################
FROM php:8.4-cli-bookworm AS app

# Install the PHP extensions Laravel needs, plus a couple of build tools.
# (ext-intl is only *suggested* by Symfony polyfills, so it is intentionally
#  left out to keep the build fast; add it back here if you need Number/locale
#  formatting helpers.)
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN chmod +x /usr/local/bin/install-php-extensions \
 && install-php-extensions pdo_sqlite mbstring bcmath zip opcache \
 && apt-get update \
 && apt-get install -y --no-install-recommends git unzip \
 && rm -rf /var/lib/apt/lists/*

# Bring in Composer from the official image.
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Install PHP dependencies first so this layer is cached unless deps change.
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-interaction --prefer-dist --optimize-autoloader

# Copy the application source.
COPY . .

# Overlay the compiled front-end assets from stage 1.
COPY --from=frontend /app/public/build ./public/build

# Prepare the environment: .env, app key, optimized autoloader, package discovery.
RUN cp .env.example .env \
 && composer dump-autoload --optimize \
 && php artisan key:generate --force \
 && php artisan package:discover --ansi

# Ensure writable dirs and a SQLite database file exist.
RUN mkdir -p storage/framework/cache storage/framework/sessions storage/framework/views storage/logs bootstrap/cache database \
 && touch database/database.sqlite \
 && chmod -R 775 storage bootstrap/cache

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 8000
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]
