# Production Compose (Coolify) + API URLs

## Compose services
| Service | Role |
|---------|------|
| `db` | MySQL 8 + volume `mysql_data` |
| `api` | Laravel on `0.0.0.0:8000` |
| `web` | Flutter SPA (Caddy); proxies `/api` → `api:8000` |

## Coolify variables (Compose resource, enable **Interpolation**)
```
DB_DATABASE=hr360_production
DB_USERNAME=hr360_user
DB_PASSWORD=<strong-password>
DB_ROOT_PASSWORD=<different-strong-password>
DB_HOST=db
DB_PORT=3306
DB_MASTER_HOST=db
DB_MASTER_PORT=3306
DB_MASTER_DATABASE=hr360_master
DB_MASTER_USERNAME=hr360_user
DB_MASTER_PASSWORD=<same-or-strong-password>
APP_KEY=<from: php artisan key:generate --show>
APP_URL=https://hr360techx.com
```

Coolify settings:
- Branch: `main`
- Compose location: `/docker-compose.yml` (only this file — no `.yaml`)
- Build strategy: Compose

`API_UPSTREAM=api:8000` is already set on **web** only.

## After first successful deploy
No manual SQL import is required.

On **api** start, `bootstrap-hr.php` applies every `database/*.sql` file, verifies
required module tables (termination, letter, training, …), and sets login
`demo` / `admin` / `admin`.

See `database/SCHEMA.md`.

Optional framework tables only:
```bash
php artisan migrate --force
```

Re-run schema inside the api container:
```bash
php artisan hr360:schema
```

API serves via **nginx + php-fpm** (not `artisan serve`) so parallel Flutter
requests do not queue and time out.

This app is **not** Laravel Breeze/Jetstream users. Login uses tenant `employee` rows
(plus `hr360_master.tenants`). There is no public registration page.

## Verify
| URL | Expect |
|-----|--------|
| `https://hr360techx.com/` | Flutter login |
| `https://hr360techx.com/up` | Laravel OK |
| `POST /api/auth/login` | JSON (not 502) |

## Flutter API URL (local unchanged)
1. `--dart-define=API_BASE_URL=...`  
2. Web prod → `{origin}/api`  
3. `flutter run` localhost:port → XAMPP  
4. Mobile release → `https://hr360techx.com/api`  
