# Database setup (HR360 Flutter replica)

All DB scripts live in this folder. **Nothing outside `HR360techx`.**

## Databases created

| Database | Role |
|----------|------|
| `hr360_master` | Tenant registry (`tenants` table) |
| `hr360_demo` | Sample organization data (employees, leave, …) |

In MySQL Yog: refresh and open `hr360_master` / `hr360_demo`.

## How multi-tenant login works

1. Flutter sends `subdomain` + username + password  
2. API looks up `hr360_master.tenants` by subdomain  
3. Connects to that tenant’s DB (`db_name`)  
4. Checks `employee` table and returns a session token  

Subdomains `demo` and `scfnew` both point at `hr360_demo` for local/dev.

## Setup / reset

```bat
database\setup.bat
```

(MySQL must be running in XAMPP.)

## Seed logins

| Org subdomain | Username | Password | Role |
|---------------|----------|----------|------|
| `demo` or `scfnew` | `admin` | `admin123` | Admin (status 2) |
| `demo` or `scfnew` | `staff` | `staff123` | Employee |

## On live hosting

Import the same SQL files on the server MySQL, then set env vars or edit `api/config.php` for host/user/pass.
