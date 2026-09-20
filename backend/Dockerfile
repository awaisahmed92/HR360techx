FROM php:8.3-cli-bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
		git unzip curl libzip-dev libpng-dev libonig-dev libxml2-dev \
	&& docker-php-ext-install pdo_mysql mbstring zip bcmath \
	&& rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html
COPY backend/composer.json backend/composer.lock ./
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-scripts
COPY backend/ .
COPY database ./database-sql
RUN composer dump-autoload --optimize \
	&& chown -R www-data:www-data storage bootstrap/cache \
	&& chmod -R 775 storage bootstrap/cache \
	&& chmod +x docker-entrypoint.sh

ENV APP_ENV=production
ENV APP_DEBUG=false
ENV HR360_SQL_DIR=/var/www/html/database-sql
EXPOSE 8000

HEALTHCHECK --interval=15s --timeout=5s --start-period=120s --retries=8 \
	CMD curl -fsS http://127.0.0.1:8000/up || exit 1

ENTRYPOINT ["./docker-entrypoint.sh"]
