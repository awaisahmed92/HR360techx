# HR360 Flutter API (standalone)

This folder is the **backend for the Flutter replica only**.

It does **not** live inside `D:\xampp\htdocs\hr` and does not modify that app.

## URL

```
http://localhost/HR360techx/api
```

Requires Apache + MySQL (same XAMPP stack). Uses existing DBs:

- `gt_hr_master` (tenants)
- Tenant DB e.g. `scfnew` (employees, leave, …)

## Config

Edit `config.php` or set env vars:

- `HR360_MASTER_HOST` (default `localhost`)
- `HR360_MASTER_DB` (default `gt_hr_master`)
- `HR360_MASTER_USER` (default `root`)
- `HR360_MASTER_PASS` (default empty)

## Endpoints

Same contract the Flutter app already calls (`/api/v1/...` also works via rewrite of path):

| Method | Path |
|--------|------|
| POST | `/auth/login` |
| GET | `/auth/me` |
| GET | `/leave` |
| GET | `/leave/types` |
| POST | `/leave/apply` |
| POST | `/leave/approve` |
| POST | `/leave/reject` |

Flutter default base URL: `http://localhost/HR360techx/api`
