#!/bin/sh
set -e

cd /var/www/html

# Coolify often injects env; generate APP_KEY if missing so the container can boot.
if [ -z "$APP_KEY" ] || [ "$APP_KEY" = "base64:" ]; then
  echo "[hr360-api] APP_KEY missing — generating one for this container"
  export APP_KEY="$(php -r "echo 'base64:'.base64_encode(random_bytes(32));")"
fi

mkdir -p storage/framework/{cache,sessions,views} storage/logs bootstrap/cache /run/nginx
chmod -R 775 storage bootstrap/cache 2>/dev/null || true

# Clear config cache so Coolify env vars are picked up on each start
php artisan config:clear 2>/dev/null || true

echo "[hr360-api] installing HR schema (idempotent)..."
php bootstrap-hr.php || echo "[hr360-api] bootstrap reported an error (see logs above)"

echo "[hr360-api] starting php-fpm + nginx on :8000 (APP_URL=${APP_URL:-unset})"
php-fpm -D
exec nginx -g 'daemon off;'
