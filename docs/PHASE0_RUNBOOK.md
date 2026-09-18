# HR360 Flutter — Runbook

## Scope (important)

**Only change files under** `D:\xampp\htdocs\HR360techx`  
Do not modify `D:\xampp\htdocs\hr` (reference / source of ideas only).

## Databases (ours)

Created by this project:

- `hr360_master` — tenants (subdomain → tenant DB)
- `hr360_demo` — sample org data

See `database/README.md`. Run `database\setup.bat` if missing.

## Run Flutter

```bash
cd d:\xampp\htdocs\HR360techx
flutter run -d chrome
```

API: `http://localhost/HR360techx/api`

## Login (live API)

Turn **Demo mode OFF**, then:

| Field | Value |
|-------|--------|
| Organization | `demo` |
| Username | `admin` |
| Password | `admin123` |

Staff: `staff` / `staff123`
