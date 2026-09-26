-- ============================================================
-- 360tech Platform — Multi-App Registry Extension
-- Extends hr360_master.tenants so that ALL 360tech apps
-- (Accounts360tech, Pos360tech, School360tech) can share the
-- same master database that HR360techx already owns.
--
-- Run AFTER 01_master.sql:
--   mysql -u root hr360_master < database/31_multi_app_registry.sql
--
-- Idempotent: safe to re-run. Uses guarded procedures for
-- MySQL 8.0 compatibility (ADD COLUMN IF NOT EXISTS is MariaDB-only).
-- ============================================================

USE hr360_master;

-- ── Per-app enabled flags ─────────────────────────────────────────────────────
-- Mirror the existing `hr_app` column, one flag per 360tech application.

DROP PROCEDURE IF EXISTS _add_col_accounts_app;
DELIMITER $$
CREATE PROCEDURE _add_col_accounts_app()
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = 'hr360_master'
          AND TABLE_NAME   = 'tenants'
          AND COLUMN_NAME  = 'accounts_app'
    ) THEN
        ALTER TABLE tenants
            ADD COLUMN accounts_app TINYINT(1) NOT NULL DEFAULT 0 AFTER hr_app;
    END IF;
END$$
DELIMITER ;
CALL _add_col_accounts_app();
DROP PROCEDURE IF EXISTS _add_col_accounts_app;

DROP PROCEDURE IF EXISTS _add_col_pos_app;
DELIMITER $$
CREATE PROCEDURE _add_col_pos_app()
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = 'hr360_master'
          AND TABLE_NAME   = 'tenants'
          AND COLUMN_NAME  = 'pos_app'
    ) THEN
        ALTER TABLE tenants
            ADD COLUMN pos_app TINYINT(1) NOT NULL DEFAULT 0 AFTER accounts_app;
    END IF;
END$$
DELIMITER ;
CALL _add_col_pos_app();
DROP PROCEDURE IF EXISTS _add_col_pos_app;

DROP PROCEDURE IF EXISTS _add_col_school_app;
DELIMITER $$
CREATE PROCEDURE _add_col_school_app()
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = 'hr360_master'
          AND TABLE_NAME   = 'tenants'
          AND COLUMN_NAME  = 'school_app'
    ) THEN
        ALTER TABLE tenants
            ADD COLUMN school_app TINYINT(1) NOT NULL DEFAULT 0 AFTER pos_app;
    END IF;
END$$
DELIMITER ;
CALL _add_col_school_app();
DROP PROCEDURE IF EXISTS _add_col_school_app;

-- ── Per-app tenant DB name columns ────────────────────────────────────────────
-- `db_name` already stores the HR tenant DB name (e.g. hr360_demo001).
-- Each additional app gets its own column so DB names can differ per app.

DROP PROCEDURE IF EXISTS _add_col_accounts_db_name;
DELIMITER $$
CREATE PROCEDURE _add_col_accounts_db_name()
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = 'hr360_master'
          AND TABLE_NAME   = 'tenants'
          AND COLUMN_NAME  = 'accounts_db_name'
    ) THEN
        ALTER TABLE tenants
            ADD COLUMN accounts_db_name VARCHAR(191) NULL AFTER db_name;
    END IF;
END$$
DELIMITER ;
CALL _add_col_accounts_db_name();
DROP PROCEDURE IF EXISTS _add_col_accounts_db_name;

DROP PROCEDURE IF EXISTS _add_col_pos_db_name;
DELIMITER $$
CREATE PROCEDURE _add_col_pos_db_name()
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = 'hr360_master'
          AND TABLE_NAME   = 'tenants'
          AND COLUMN_NAME  = 'pos_db_name'
    ) THEN
        ALTER TABLE tenants
            ADD COLUMN pos_db_name VARCHAR(191) NULL AFTER accounts_db_name;
    END IF;
END$$
DELIMITER ;
CALL _add_col_pos_db_name();
DROP PROCEDURE IF EXISTS _add_col_pos_db_name;

DROP PROCEDURE IF EXISTS _add_col_school_db_name;
DELIMITER $$
CREATE PROCEDURE _add_col_school_db_name()
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = 'hr360_master'
          AND TABLE_NAME   = 'tenants'
          AND COLUMN_NAME  = 'school_db_name'
    ) THEN
        ALTER TABLE tenants
            ADD COLUMN school_db_name VARCHAR(191) NULL AFTER pos_db_name;
    END IF;
END$$
DELIMITER ;
CALL _add_col_school_db_name();
DROP PROCEDURE IF EXISTS _add_col_school_db_name;

-- ── Seed: register demo001 as the first Accounts360tech tenant ────────────────
-- If the demo001 subdomain row already exists (inserted by 01_master.sql or
-- by HR bootstrap), just set the accounts fields. Otherwise insert a new row.

INSERT INTO tenants
    (name, subdomain, db_host, db_name, db_user, db_password, status,
     hr_app, accounts_app, accounts_db_name)
VALUES
    ('Demo Org 001', 'demo001', 'localhost', 'hr360_demo001', 'root', '', 'active',
     0, 1, 'accounts360_demo001')
ON DUPLICATE KEY UPDATE
    accounts_app     = 1,
    accounts_db_name = 'accounts360_demo001';

-- ── Column summary after this migration ──────────────────────────────────────
-- tenants.hr_app          TINYINT(1)   HR360techx enabled for this org
-- tenants.accounts_app    TINYINT(1)   Accounts360tech enabled          ← NEW
-- tenants.pos_app         TINYINT(1)   Pos360tech enabled (future stub) ← NEW
-- tenants.school_app      TINYINT(1)   School360tech enabled (stub)     ← NEW
-- tenants.db_name         VARCHAR(191) HR tenant DB  (e.g. hr360_demo001)
-- tenants.accounts_db_name VARCHAR(191) Accounts DB (e.g. accounts360_demo001) ← NEW
-- tenants.pos_db_name     VARCHAR(191) POS tenant DB (future)           ← NEW
-- tenants.school_db_name  VARCHAR(191) School tenant DB (future)        ← NEW
