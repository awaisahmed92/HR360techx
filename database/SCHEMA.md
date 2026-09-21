# HR360 database schema

One installer, `backend/bootstrap-hr.php`, builds and repairs the schema. It runs on
every production container start and you run the same script locally, so local and
production can no longer drift apart silently.

## Why tables and columns used to go missing on production

Two separate causes, both now fixed:

1. **Columns that only ever existed on your laptop.** Changes made directly in
   phpMyAdmin were never written into a `database/*.sql` file, so production had no
   way to learn about them. 33 such columns existed (31 on `employee`, plus
   `attendance.status` and `leave.assigned`).
2. **SQL errors that were swallowed.** `15_payroll_pending.sql` adds
   `process_salary.late_amount AFTER advance_amount`, but `advance_amount` was only
   created by a commented-out statement in `13_payroll_setup.sql`. On a fresh database
   that `ALTER` failed, and because one `ALTER` carried four `ADD COLUMN` clauses, all
   four columns were lost. The old installer only checked a hand-written list of table
   names, so it never noticed and reported success.

The installer now derives its expectations from the SQL files themselves: every
`CREATE TABLE x` means `x` must exist afterwards, and every
`ALTER TABLE x ADD COLUMN y` means `x.y` must exist afterwards. Nothing to register by
hand. If something is missing it re-applies the file, and if it is still missing the
command exits non-zero with a list.

## Daily process

Pick whichever of the two matches how you made the change.

### A. You changed the database by hand (phpMyAdmin, SQL tab, GUI)

```powershell
.\db.bat capture my_change_name   # writes database\NN_my_change_name.sql
.\db.bat check                    # must print: OK — schema is complete
git add database\NN_my_change_name.sql
git commit -m "Add my_change_name columns"
git push
```

`capture` compares the live database against everything the SQL files promise and
writes the difference out as idempotent, re-runnable SQL.

### B. You want to write the SQL first

```powershell
.\db.bat new my_change_name       # creates database\NN_my_change_name.sql
# edit the file
.\db.bat apply                    # applies it to hr360_demo
.\db.bat check
git add database\NN_my_change_name.sql && git commit -m "..." && git push
```

Deploying is then just a redeploy in Coolify — the container runs the installer itself.

## Commands

| Command | Meaning |
| --- | --- |
| `.\db.bat check` | List missing tables/columns. Changes nothing. Exit 1 if incomplete. |
| `.\db.bat apply` | Apply new or changed SQL files, then verify. |
| `.\db.bat capture <name>` | Write hand-made local changes into a new SQL file. |
| `.\db.bat new <name>` | Scaffold the next numbered SQL file. |
| `.\db.bat force` | Re-apply every SQL file. |

Inside the api container (or anywhere Laravel is booted) the same thing is available as
`php artisan hr360:schema`, `php artisan hr360:schema --check`, `--force`,
`--capture=name`, `--new=name`, `--file=29_status_feed.sql`.

## Rules for writing SQL files

- Always `CREATE TABLE IF NOT EXISTS`.
- Add columns with the guarded block that `db new` scaffolds. `ADD COLUMN IF NOT EXISTS`
  is MariaDB-only and silently unusable on MySQL 8.
- Never edit an already-deployed file to change existing data; add a new file instead.
  Editing is safe for adding things — the installer notices the checksum change and
  re-applies the file.
- Keep `USE hr360_demo;` at the top. The installer rewrites it to the real database.

## What a production deploy does

On every **api** container start, `docker-entrypoint.sh` runs:

1. `php bootstrap-hr.php`
2. on failure, one retry with `--force`
3. on continued failure, a loud banner in the logs; set `HR360_SCHEMA_STRICT=1` in
   Coolify if you would rather the deploy fail outright than start with a partial schema

The installer creates `hr360_master` and the tenant DB (needs `DB_ROOT_PASSWORD`),
registers organization `demo`, applies every `database/*.sql` in order while rewriting
`hr360_demo` to your `DB_DATABASE`, records each file with its checksum in
`_schema_migrations`, and sets the login `demo` / `admin` / `admin`.

To inspect a live production database:

```bash
php bootstrap-hr.php --check
```

## Local notes

Defaults are already local XAMPP (`127.0.0.1`, `hr360_demo`, user `root`, no password),
so `.\db.bat check` needs no configuration. Do not point your local `.env` at the
Coolify MySQL server.
