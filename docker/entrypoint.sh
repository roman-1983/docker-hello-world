#!/bin/sh
set -e

export APP_ENV="${APP_ENV:-prod}"

echo "Waiting for database..."
max_tries="${DB_WAIT_TRIES:-60}"
i=0

until php -r "
  \$url = getenv('DATABASE_URL');
  if (!\$url) { fwrite(STDERR, \"DATABASE_URL missing\n\"); exit(2); }
  \$p = parse_url(\$url);
  \$host = \$p['host'] ?? 'db';
  \$port = \$p['port'] ?? 5432;
  \$db   = ltrim(\$p['path'] ?? '', '/');
  \$user = \$p['user'] ?? '';
  \$pass = \$p['pass'] ?? '';
  try {
    new PDO(\"pgsql:host=\$host;port=\$port;dbname=\$db\", \$user, \$pass, [PDO::ATTR_TIMEOUT=>2]);
  } catch (Throwable \$e) { exit(1); }
  exit(0);
" 2>/dev/null; do
  i=$((i+1))
  if [ "$i" -ge "$max_tries" ]; then
    echo "Database not reachable after ${max_tries}s (DB_WAIT_TRIES). Exiting."
    exit 1
  fi
  sleep 1
done

echo "Database is up."

echo "Running migrations (env=$APP_ENV)..."
php bin/console doctrine:migrations:migrate --no-interaction --allow-no-migration --env="$APP_ENV"

echo "Warming cache (env=$APP_ENV)..."
php bin/console cache:warmup --env="$APP_ENV"

echo "Starting FrankenPHP..."
exec frankenphp run --config /etc/caddy/Caddyfile
