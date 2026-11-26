-- Login security tables on the MASTER database (not the tenant DB).
-- Applied by: php bootstrap-hr.php
--   (or)     php bootstrap-hr.php --file=40_login_security_master.sql
-- USE hr360_master is rewritten to DB_MASTER_DATABASE (e.g. 360_master on production).

USE `hr360_master`;

CREATE TABLE IF NOT EXISTS `hr_login_attempts` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `ip` VARCHAR(64) NOT NULL,
  `subdomain` VARCHAR(100) NULL,
  `username` VARCHAR(191) NULL,
  `success` TINYINT(1) NOT NULL DEFAULT 0,
  `reason` VARCHAR(80) NULL,
  `suspicious` TINYINT(1) NOT NULL DEFAULT 0,
  `user_agent` VARCHAR(255) NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_login_ip_time` (`ip`, `created_at`),
  KEY `idx_login_acct_time` (`subdomain`, `username`, `created_at`),
  KEY `idx_login_suspicious` (`suspicious`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_ip_blocks` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `ip` VARCHAR(64) NOT NULL,
  `reason` VARCHAR(191) NOT NULL,
  `blocked_until` DATETIME NOT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ip_blocks_ip` (`ip`),
  KEY `idx_ip_blocks_until` (`blocked_until`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_account_locks` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `subdomain` VARCHAR(100) NOT NULL,
  `username` VARCHAR(191) NOT NULL,
  `fail_count` INT UNSIGNED NOT NULL DEFAULT 0,
  `locked_until` DATETIME NULL,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_acct_lock` (`subdomain`, `username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
