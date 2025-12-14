#!/bin/sh
set -e

echo "Waiting for database..."
until php -r "
  \$url = getenv('DATABASE_URL');
  if (!\$url) { fwrite(STDERR, \"DATABASE_URL missing\n\"); exit(1); }
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
"; do
  sleep 1
done

echo "Database is up."

echo "Running migrations..."
php bin/console doctrine:migrations:migrate --no-interaction --allow-no-migration

echo "Warming cache..."
php bin/console cache:warmup --env=prod

echo "Starting FrankenPHP..."
exec frankenphp run --config /etc/caddy/Caddyfile
