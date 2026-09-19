# How API URLs resolve (Flutter)

## Priority
1. `--dart-define=API_BASE_URL=...` (optional override)
2. **Web** → `{currentOrigin}/api`  
   - Production: `https://hr360techx.com/api`  
   - Exception: `flutter run` on `localhost:xxxxx` → XAMPP  
     `http://localhost/HR360techx/backend/public/api`
3. **Mobile release** → `https://hr360techx.com/api`
4. **Mobile debug** → Android emulator `10.0.2.2/...`, iOS sim `localhost/...`

## Local
```bash
flutter run -d chrome
# or
flutter run -d windows
```
XAMPP Apache + MySQL must be running.

Physical phone on Wi‑Fi:
```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.10/HR360techx/backend/public/api
```

## Production (Coolify)
Use `docker-compose.yml` (web + api) so Caddy proxies `/api` to Laravel.
Set DB + `APP_KEY` on the `api` service. Redeploy after push.
