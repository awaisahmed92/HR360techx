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
In the **api** container terminal:
```bash
php artisan migrate --force
```

This app is **not** Laravel Breeze/Jetstream users. Login uses tenant `employee` rows
(plus `hr360_master.tenants`). After migrate you still need:

1. Master DB `hr360_master` with a `tenants` row (e.g. subdomain `demo` → tenant DB).
2. At least one employee in the tenant DB with bcrypt password.

Import from local XAMPP dumps (`hr360_master` + `hr360_demo`) or run your SQL under `database/` if that is how the schema is bootstrapped.

Create login (example, after schema exists) — prefer importing a known admin from local, or insert via SQL with a bcrypt hash. There is no public registration page.

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
