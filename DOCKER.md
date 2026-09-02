# Running this Laravel demo with Docker

This project ships as a self-contained Docker image, so you don't need PHP,
Composer or Node installed on the host — only Docker.

## Quick start

```bash
docker compose up -d --build     # build the image and start the app
```

Then open <http://localhost:8000>.

```bash
docker compose logs -f           # follow the server / migration output
docker compose down              # stop and remove the container
```

## What the image does

The build is a two-stage `Dockerfile`:

1. **`frontend` stage** (`node:22`) runs `npm install && npm run build` to
   compile the Vite + Tailwind 4 assets into `public/build`.
2. **`app` stage** (`php:8.4-cli`) installs the required PHP extensions,
   installs Composer dependencies (`--no-dev`), copies the source and the
   compiled assets, sets `APP_KEY`, and runs package discovery.

At container start, `docker-entrypoint.sh`:

- ensures the SQLite database file exists (`database/database.sqlite`),
- runs `php artisan migrate --force` (sessions, cache and queue use the DB), and
- serves the app with `php artisan serve` on `0.0.0.0:8000`.

## Notes

- **Database:** SQLite, baked into the container. Data resets on `docker compose down`.
- **Editing code:** the image bakes the source in (no bind mount — bind mounts
  are very slow on Windows). After changing code, rebuild with
  `docker compose up -d --build`.
- **`ext-intl`:** left out of the image to keep builds fast. Add it back to the
  `install-php-extensions` line in the `Dockerfile` if you need locale/number
  formatting helpers.
