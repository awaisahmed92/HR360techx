-- Phase 2: Organization masters + employee lifecycle + timesheet/payroll masters
-- Safe to re-run. Links: company → division → dept → team; station/project FKs on employee flows.
USE `hr360_demo`;

-- ── Organization hierarchy ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `hr_org_division` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(40) DEFAULT NULL,
  `name` VARCHAR(191) NOT NULL,
  `company_id` INT UNSIGNED DEFAULT NULL,
  `status` TINYINT NOT NULL DEFAULT 1 COMMENT '1 active, 0 inactive',
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_div_company` (`company_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_cost_center` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(40) DEFAULT NULL,
  `name` VARCHAR(191) NOT NULL,
  `division_id` INT UNSIGNED DEFAULT NULL,
  `status` TINYINT NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_cc_div` (`division_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_parent_department` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(40) DEFAULT NULL,
  `name` VARCHAR(191) NOT NULL,
  `division_id` INT UNSIGNED DEFAULT NULL,
  `status` TINYINT NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_team` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(40) DEFAULT NULL,
  `name` VARCHAR(191) NOT NULL,
  `department_id` INT UNSIGNED DEFAULT NULL,
  `lead_employee_id` INT UNSIGNED DEFAULT NULL,
  `status` TINYINT NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_team_dept` (`department_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_announcement` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `title` VARCHAR(191) NOT NULL,
  `body` TEXT NULL,
  `audience` VARCHAR(50) DEFAULT 'all',
  `starts_on` DATE DEFAULT NULL,
  `ends_on` DATE DEFAULT NULL,
  `status` TINYINT NOT NULL DEFAULT 1,
  `created_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_policy` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `title` VARCHAR(191) NOT NULL,
  `category` VARCHAR(80) DEFAULT NULL,
  `file_path` VARCHAR(255) DEFAULT NULL,
  `version` VARCHAR(20) DEFAULT '1.0',
  `status` TINYINT NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_system_log` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `actor_id` INT UNSIGNED DEFAULT NULL,
  `action` VARCHAR(80) NOT NULL,
  `entity` VARCHAR(80) DEFAULT NULL,
  `entity_id` INT UNSIGNED DEFAULT NULL,
  `detail` TEXT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_log_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Soft-extend department with linkages (ignore if columns exist)
SET @db := DATABASE();

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE department ADD COLUMN code VARCHAR(40) NULL AFTER name',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='department' AND COLUMN_NAME='code');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE department ADD COLUMN parent_department_id INT UNSIGNED NULL',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='department' AND COLUMN_NAME='parent_department_id');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE department ADD COLUMN division_id INT UNSIGNED NULL',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='department' AND COLUMN_NAME='division_id');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE department ADD COLUMN cost_center_id INT UNSIGNED NULL',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='department' AND COLUMN_NAME='cost_center_id');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE department ADD COLUMN status TINYINT NOT NULL DEFAULT 1',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='department' AND COLUMN_NAME='status');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE station ADD COLUMN code VARCHAR(40) NULL AFTER name',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='station' AND COLUMN_NAME='code');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE station ADD COLUMN status TINYINT NOT NULL DEFAULT 1',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='station' AND COLUMN_NAME='status');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE company ADD COLUMN contact_person VARCHAR(191) NULL',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='company' AND COLUMN_NAME='contact_person');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE company ADD COLUMN address VARCHAR(255) NULL',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='company' AND COLUMN_NAME='address');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE company ADD COLUMN province VARCHAR(100) NULL',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='company' AND COLUMN_NAME='province');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE company ADD COLUMN website VARCHAR(191) NULL',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='company' AND COLUMN_NAME='website');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE company ADD COLUMN status TINYINT NOT NULL DEFAULT 1',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='company' AND COLUMN_NAME='status');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE company ADD COLUMN company_type VARCHAR(50) DEFAULT ''Head Office''',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='company' AND COLUMN_NAME='company_type');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ── Employee lifecycle (linked to employee / project / station / designation) ──
CREATE TABLE IF NOT EXISTS `hr_contract` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `employee_id` INT UNSIGNED NOT NULL,
  `contract_no` VARCHAR(60) DEFAULT NULL,
  `contract_type` VARCHAR(60) DEFAULT 'Permanent',
  `start_date` DATE DEFAULT NULL,
  `end_date` DATE DEFAULT NULL,
  `project_id` INT UNSIGNED DEFAULT NULL,
  `station_id` INT UNSIGNED DEFAULT NULL,
  `status` TINYINT NOT NULL DEFAULT 1,
  `notes` TEXT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_contract_emp` (`employee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_assignment` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `employee_id` INT UNSIGNED NOT NULL,
  `project_id` INT UNSIGNED DEFAULT NULL,
  `station_id` INT UNSIGNED DEFAULT NULL,
  `department_id` INT UNSIGNED DEFAULT NULL,
  `role_title` VARCHAR(191) DEFAULT NULL,
  `start_date` DATE DEFAULT NULL,
  `end_date` DATE DEFAULT NULL,
  `status` TINYINT NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_assign_emp` (`employee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_transfer` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `employee_id` INT UNSIGNED NOT NULL,
  `from_station_id` INT UNSIGNED DEFAULT NULL,
  `to_station_id` INT UNSIGNED DEFAULT NULL,
  `from_project_id` INT UNSIGNED DEFAULT NULL,
  `to_project_id` INT UNSIGNED DEFAULT NULL,
  `effective_date` DATE DEFAULT NULL,
  `reason` TEXT NULL,
  `status` TINYINT NOT NULL DEFAULT 0 COMMENT '0 pending, 1 approved, 2 rejected',
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_promotion` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `employee_id` INT UNSIGNED NOT NULL,
  `from_designation_id` INT UNSIGNED DEFAULT NULL,
  `to_designation_id` INT UNSIGNED DEFAULT NULL,
  `effective_date` DATE DEFAULT NULL,
  `remarks` TEXT NULL,
  `status` TINYINT NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_resignation` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `employee_id` INT UNSIGNED NOT NULL,
  `resign_date` DATE DEFAULT NULL,
  `last_working_day` DATE DEFAULT NULL,
  `reason` TEXT NULL,
  `status` TINYINT NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_employment_change` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `employee_id` INT UNSIGNED NOT NULL,
  `change_type` VARCHAR(80) NOT NULL,
  `effective_date` DATE DEFAULT NULL,
  `old_value` VARCHAR(255) DEFAULT NULL,
  `new_value` VARCHAR(255) DEFAULT NULL,
  `remarks` TEXT NULL,
  `status` TINYINT NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_achievement` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `employee_id` INT UNSIGNED NOT NULL,
  `title` VARCHAR(191) NOT NULL,
  `achieved_on` DATE DEFAULT NULL,
  `description` TEXT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_complaint` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `employee_id` INT UNSIGNED NOT NULL,
  `against_employee_id` INT UNSIGNED DEFAULT NULL,
  `subject` VARCHAR(191) NOT NULL,
  `detail` TEXT NULL,
  `status` TINYINT NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_discipline` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `employee_id` INT UNSIGNED NOT NULL,
  `action_type` VARCHAR(80) NOT NULL,
  `action_date` DATE DEFAULT NULL,
  `detail` TEXT NULL,
  `status` TINYINT NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ── Timesheet masters ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `hr_work_shift` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(40) DEFAULT NULL,
  `name` VARCHAR(191) NOT NULL,
  `start_time` TIME DEFAULT NULL,
  `end_time` TIME DEFAULT NULL,
  `grace_minutes` INT DEFAULT 15,
  `status` TINYINT NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_holiday` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(191) NOT NULL,
  `holiday_date` DATE NOT NULL,
  `holiday_type` VARCHAR(50) DEFAULT 'Public',
  `status` TINYINT NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_wfh_request` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `employee_id` INT UNSIGNED NOT NULL,
  `from_date` DATE NOT NULL,
  `to_date` DATE NOT NULL,
  `reason` TEXT NULL,
  `status` TINYINT NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_flex_hour` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `employee_id` INT UNSIGNED NOT NULL,
  `work_date` DATE NOT NULL,
  `planned_in` TIME DEFAULT NULL,
  `planned_out` TIME DEFAULT NULL,
  `reason` TEXT NULL,
  `status` TINYINT NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ── Payroll masters (Phase 3 foundation — NOT full salary process) ──
CREATE TABLE IF NOT EXISTS `hr_payroll_item` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(40) DEFAULT NULL,
  `name` VARCHAR(191) NOT NULL,
  `category` VARCHAR(40) NOT NULL COMMENT 'allowance|deduction|bonus|earning|commission|overtime|adjustment',
  `calc_type` VARCHAR(40) DEFAULT 'fixed' COMMENT 'fixed|percent|formula',
  `default_value` DECIMAL(12,2) DEFAULT 0,
  `taxable` TINYINT(1) NOT NULL DEFAULT 1,
  `status` TINYINT NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_payitem_cat` (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_salary_scale` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(40) DEFAULT NULL,
  `name` VARCHAR(191) NOT NULL,
  `min_amount` DECIMAL(12,2) DEFAULT 0,
  `max_amount` DECIMAL(12,2) DEFAULT 0,
  `designation_id` INT UNSIGNED DEFAULT NULL,
  `status` TINYINT NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_hourly_wage` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `employee_id` INT UNSIGNED DEFAULT NULL,
  `designation_id` INT UNSIGNED DEFAULT NULL,
  `rate_per_hour` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `effective_from` DATE DEFAULT NULL,
  `status` TINYINT NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_advance` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `employee_id` INT UNSIGNED NOT NULL,
  `amount` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `request_date` DATE DEFAULT NULL,
  `recover_months` INT DEFAULT 1,
  `status` TINYINT NOT NULL DEFAULT 0,
  `remarks` TEXT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_overtime_entry` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `employee_id` INT UNSIGNED NOT NULL,
  `work_date` DATE NOT NULL,
  `hours` DECIMAL(8,2) NOT NULL DEFAULT 0,
  `rate_multiplier` DECIMAL(4,2) DEFAULT 1.5,
  `status` TINYINT NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Seed payroll item categories (idempotent)
INSERT INTO `hr_payroll_item` (`code`, `name`, `category`, `calc_type`, `default_value`, `taxable`)
SELECT 'BASIC', 'Basic Salary', 'earning', 'fixed', 0, 1 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM hr_payroll_item WHERE code='BASIC');
INSERT INTO `hr_payroll_item` (`code`, `name`, `category`, `calc_type`, `default_value`, `taxable`)
SELECT 'HRA', 'House Rent Allowance', 'allowance', 'percent', 45, 1 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM hr_payroll_item WHERE code='HRA');
INSERT INTO `hr_payroll_item` (`code`, `name`, `category`, `calc_type`, `default_value`, `taxable`)
SELECT 'EOBI', 'EOBI Deduction', 'deduction', 'fixed', 0, 0 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM hr_payroll_item WHERE code='EOBI');
INSERT INTO `hr_payroll_item` (`code`, `name`, `category`, `calc_type`, `default_value`, `taxable`)
SELECT 'BONUS', 'Annual Bonus', 'bonus', 'fixed', 0, 1 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM hr_payroll_item WHERE code='BONUS');
INSERT INTO `hr_payroll_item` (`code`, `name`, `category`, `calc_type`, `default_value`, `taxable`)
SELECT 'COMM', 'Sales Commission', 'commission', 'percent', 0, 1 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM hr_payroll_item WHERE code='COMM');
INSERT INTO `hr_payroll_item` (`code`, `name`, `category`, `calc_type`, `default_value`, `taxable`)
SELECT 'OT', 'Overtime Pay', 'overtime', 'formula', 0, 1 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM hr_payroll_item WHERE code='OT');
INSERT INTO `hr_payroll_item` (`code`, `name`, `category`, `calc_type`, `default_value`, `taxable`)
SELECT 'ADJ', 'Salary Adjustment', 'adjustment', 'fixed', 0, 1 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM hr_payroll_item WHERE code='ADJ');
