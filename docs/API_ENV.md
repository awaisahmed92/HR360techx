# API environment (local + production)

## Why you saw 502
Flutter now correctly calls `https://hr360techx.com/api/...`.
**502 Bad Gateway** means Caddy reached `/api` but the **Laravel `api` container was down / unreachable**.

## Coolify (required)
1. Delete or stop any **Flutter-only / single Dockerfile** resource for this domain.
2. Create a **Docker Compose** resource pointing at this repo.
3. Compose file: `docker-compose.yml` (services **`web`** + **`api`**).
4. On **`api`** set:
   - `APP_KEY` — generate with `php artisan key:generate --show` locally
   - `APP_URL=https://hr360techx.com`
   - `DB_CONNECTION=mysql`
   - `DB_HOST` / `DB_PORT` / `DB_DATABASE` / `DB_USERNAME` / `DB_PASSWORD`
   - Master DB vars if used (`DB_MASTER_*`)
5. On **`web`** set:
   - `API_UPSTREAM=api:8000`  ← must be `host:port`, **no** `http://`
6. Deploy. Wait until **`api` is healthy** (`/up` returns 200), then test login.

### Quick checks after deploy
| URL | Expected |
|-----|----------|
| `https://hr360techx.com/` | Flutter login |
| `https://hr360techx.com/up` | Laravel health JSON/OK (via proxy) |
| `POST https://hr360techx.com/api/auth/login` | JSON (not 502 / not HTML) |

If `api` logs show DB connection refused → fix `DB_HOST` (Coolify DB service name or public host).  
If `api` restarts → missing `APP_KEY` or crash on boot (check logs).

## Flutter API URL resolution
1. `--dart-define=API_BASE_URL=...` override  
2. **Web** → `{origin}/api` (production = same host)  
3. **Web debug** `localhost:xxxxx` → XAMPP  
4. **Mobile release** → `https://hr360techx.com/api`  
5. **Android emulator** → `http://10.0.2.2/HR360techx/backend/public/api`  
6. **iOS simulator** → XAMPP localhost  

## Local (unchanged)
```bash
# XAMPP Apache + MySQL
flutter run -d chrome
```
