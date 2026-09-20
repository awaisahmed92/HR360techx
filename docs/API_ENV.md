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
No manual SQL import is required for a fresh Coolify stack.

On **api** start, `bootstrap-hr.php` will:
1. Create `hr360_master` + tenant DB (needs `DB_ROOT_PASSWORD`)
2. Upsert tenant subdomain `demo` → your `DB_DATABASE` on host `db`
3. Apply every `database/*.sql` file (rewritten from `hr360_demo` → production DB name)
4. Set login: organization `demo`, employee `admin`, password `admin`

Optional Laravel framework tables only:
```bash
php artisan migrate --force
```

This app is **not** Laravel Breeze/Jetstream users. Login uses tenant `employee` rows
(plus `hr360_master.tenants`). There is no public registration page.

Schema files are tracked in tenant table `_schema_migrations` so restarts only apply new SQL.

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
