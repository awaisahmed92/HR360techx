-- Phase 3: Define / Process salary + PK tax slabs + EOBI (demo tenant)
USE `hr360_demo`;

CREATE TABLE IF NOT EXISTS `define_salary` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `station_id` INT UNSIGNED NOT NULL DEFAULT 1,
  `project_id` INT UNSIGNED NOT NULL DEFAULT 1,
  `employee_id` INT UNSIGNED NOT NULL,
  `basic_salary` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `total_allowance` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `total_deduction` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `net_salary` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `created_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_def_emp` (`employee_id`),
  KEY `idx_def_proj` (`project_id`),
  UNIQUE KEY `uq_def_emp_proj_st` (`employee_id`, `project_id`, `station_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `define_salary_details` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `define_salary_id` INT UNSIGNED NOT NULL,
  `payroll_item_id` INT UNSIGNED NOT NULL,
  `allowance` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `deduction` DECIMAL(12,2) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_defd` (`define_salary_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `process_salary` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `project_id` INT UNSIGNED NOT NULL DEFAULT 1,
  `employee_id` INT UNSIGNED NOT NULL,
  `days` INT NOT NULL DEFAULT 30,
  `basic_salary` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `total_allowance` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `total_deduction` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `net_salary` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `tax_amount` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `eobi_amount` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `date` DATE DEFAULT NULL,
  `created_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_proc_date` (`date`),
  KEY `idx_proc_proj` (`project_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `process_salary_details` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `process_salary_id` INT UNSIGNED NOT NULL,
  `payroll_item_id` INT UNSIGNED NOT NULL,
  `allowance` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `deduction` DECIMAL(12,2) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_procd` (`process_salary_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `tax` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `from_amount` INT NOT NULL,
  `to_amount` INT DEFAULT NULL,
  `fixed_amount` INT DEFAULT 0,
  `percentage` INT DEFAULT 0,
  `year` VARCHAR(20) DEFAULT '2025-2026',
  `status` TINYINT DEFAULT 1,
  `added_on` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `eobi` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `emp_amount` DECIMAL(12,2) NOT NULL DEFAULT 370,
  `emp_percentage` DECIMAL(8,2) DEFAULT NULL,
  `org_amount` DECIMAL(12,2) DEFAULT 370,
  `org_percentage` DECIMAL(8,2) DEFAULT NULL,
  `description` TEXT NULL,
  `added_on` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- PK FY 2025-26 style slabs (annual taxable income)
DELETE FROM `tax` WHERE `year` = '2025-2026';
INSERT INTO `tax` (`from_amount`, `to_amount`, `fixed_amount`, `percentage`, `year`, `status`) VALUES
(1, 600000, 0, 0, '2025-2026', 1),
(600001, 1200000, 0, 1, '2025-2026', 1),
(1200001, 2200000, 6000, 11, '2025-2026', 1),
(2200001, 3200000, 116000, 23, '2025-2026', 1),
(3200001, 4100000, 346000, 30, '2025-2026', 1),
(4100001, 2147483647, 616000, 35, '2025-2026', 1);

INSERT INTO `eobi` (`emp_amount`, `org_amount`, `description`)
SELECT 370, 370, 'Default EOBI employee/employer contribution'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM eobi LIMIT 1);

-- Ensure BASIC exists in hr_payroll_item for define forms
INSERT INTO `hr_payroll_item` (`code`, `name`, `category`, `calc_type`, `default_value`, `taxable`)
SELECT 'BASIC', 'Basic Salary', 'earning', 'fixed', 0, 1 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM hr_payroll_item WHERE code='BASIC');
INSERT INTO `hr_payroll_item` (`code`, `name`, `category`, `calc_type`, `default_value`, `taxable`)
SELECT 'TAX', 'Income Tax', 'deduction', 'formula', 0, 0 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM hr_payroll_item WHERE code='TAX');
INSERT INTO `hr_payroll_item` (`code`, `name`, `category`, `calc_type`, `default_value`, `taxable`)
SELECT 'EOBI_E', 'EOBI Employee', 'deduction', 'fixed', 370, 0 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM hr_payroll_item WHERE code='EOBI_E');
