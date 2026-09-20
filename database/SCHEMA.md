# HR360 database schema (one install for production)

Local XAMPP already has tables because you imported `database/*.sql` by hand over time.

Production Coolify starts empty. Laravel `php artisan migrate` only creates framework
tables (`users`, `jobs`, …) — **not** HR tables. That mismatch is why Modules worked
locally and failed on production with “Run database/XX.sql”.

## How production installs schema now

On every **api** container start:

```text
php bootstrap-hr.php
```

That script:

1. Creates `hr360_master` + tenant DB (needs `DB_ROOT_PASSWORD`)
2. Registers organization `demo`
3. Applies every `database/*.sql` file in order (rewrites `hr360_demo` → your `DB_DATABASE`)
4. Tracks files in `_schema_migrations`
5. **Re-applies** a file if its required tables are still missing
6. Sets login: organization `demo` / employee `admin` / password `admin`

You do **not** run individual SQL files on the VPS for a normal deploy.

## Manual re-run (api container)

```bash
php bootstrap-hr.php
# or
php artisan hr360:schema
```

## Local XAMPP

Keep importing SQL into `hr360_demo` / `hr360_master` as before. Do not point local
`.env` at Coolify MySQL.

## Why the app felt “super slow” on production

The API used `php artisan serve` (one request at a time). Flutter fires many API calls
in parallel → queue → 20s timeouts. Production now uses **nginx + php-fpm** so those
calls run concurrently.
