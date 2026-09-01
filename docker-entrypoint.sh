#!/bin/sh
set -e

cd /var/www/html

# Make sure the SQLite database file exists (e.g. when using a fresh volume).
if [ ! -f database/database.sqlite ]; then
    touch database/database.sqlite
fi

# Apply database migrations. Sessions, cache and queue all use the DB driver,
# so the app needs these tables before it can serve a request.
php artisan migrate --force --no-interaction

# Hand off to the container command (php artisan serve ...).
exec "$@"
