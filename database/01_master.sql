-- HR360 Flutter replica — MASTER database
-- Registry of tenants (organizations). Each tenant has its own DB.

CREATE DATABASE IF NOT EXISTS `hr360_master`
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE `hr360_master`;

CREATE TABLE IF NOT EXISTS `tenants` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(191) NOT NULL,
  `subdomain` VARCHAR(100) NOT NULL,
  `db_host` VARCHAR(191) NOT NULL DEFAULT 'localhost',
  `db_name` VARCHAR(191) NOT NULL,
  `db_user` VARCHAR(191) NOT NULL DEFAULT 'root',
  `db_password` VARCHAR(191) NOT NULL DEFAULT '',
  `status` ENUM('active','inactive','suspended') NOT NULL DEFAULT 'active',
  `hr_app` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `company_code` VARCHAR(100) NULL,
  `industry` VARCHAR(120) NULL,
  `country` VARCHAR(120) NULL,
  `contact_name` VARCHAR(191) NULL,
  `contact_designation` VARCHAR(191) NULL,
  `contact_email` VARCHAR(191) NULL,
  `contact_phone` VARCHAR(60) NULL,
  `source` VARCHAR(40) NOT NULL DEFAULT 'manual',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tenants_subdomain` (`subdomain`),
  KEY `idx_tenants_company_code` (`company_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Admin user recorded at self sign-up. Credentials live in the tenant DB;
-- this is the master-side record of who owns the organization.
CREATE TABLE IF NOT EXISTS `tenant_admins` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` INT UNSIGNED NOT NULL,
  `name` VARCHAR(191) NOT NULL,
  `designation` VARCHAR(191) NULL,
  `email` VARCHAR(191) NOT NULL,
  `user_name` VARCHAR(100) NOT NULL,
  `employee_id` INT UNSIGNED NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_tenant_admins_tenant` (`tenant_id`),
  KEY `idx_tenant_admins_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Demo organization → tenant DB hr360_demo
INSERT INTO `tenants`
  (`name`, `subdomain`, `db_host`, `db_name`, `db_user`, `db_password`, `status`, `hr_app`)
VALUES
  ('HR360 Demo Org', 'demo', 'localhost', 'hr360_demo', 'root', '', 'active', 1),
  ('SCF Sample', 'scfnew', 'localhost', 'hr360_demo', 'root', '', 'active', 1)
ON DUPLICATE KEY UPDATE
  `name` = VALUES(`name`),
  `db_name` = VALUES(`db_name`),
  `status` = VALUES(`status`),
  `hr_app` = VALUES(`hr_app`);
