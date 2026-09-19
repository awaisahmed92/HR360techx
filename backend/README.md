# HR360 Laravel API

Laravel 12 backend for the Flutter replica.  
**Location:** `HR360techx/backend` only (not the old PHP HR app).

## URL (XAMPP)

```
http://localhost/HR360techx/backend/public/api
```

Flutter `AppConfig.apiBaseUrl` points here.

## Databases

Uses existing:

- `hr360_master` (tenants)
- `hr360_demo` (tenant data)

Configured in `.env`.

## Legacy Core PHP

Old `api/` folder was renamed to `api_legacy_corephp` (unused). Safe to delete later.

## Run / test

```bash
cd backend
php artisan route:list --path=api
```

Login: `POST /api/auth/login` with `{ subdomain, username, password }`.
