-- Phase 3b: Payroll Setup + statutory + banks + SESSI/PF columns
USE `hr360_demo`;

CREATE TABLE IF NOT EXISTS `hr_payroll_setup` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL DEFAULT 'General Payroll',
  `payroll_type` VARCHAR(80) NOT NULL DEFAULT 'Payroll (Pakistan)',
  `pay_schedule` VARCHAR(40) NOT NULL DEFAULT 'Monthly (12)',
  `salaries_per_year` INT NOT NULL DEFAULT 12,
  `fiscal_start_month` VARCHAR(20) NOT NULL DEFAULT 'January',
  `divide_with_days` TINYINT(1) NOT NULL DEFAULT 1,
  `per_day_method` VARCHAR(120) NOT NULL DEFAULT 'Method 1 - Annual Gross Salary / 365',
  `pro_rata_method` VARCHAR(120) NOT NULL DEFAULT 'Method 1 - Based on Annual Gross Salary',
  `exit_join_proration` VARCHAR(60) NOT NULL DEFAULT 'Prorated Salary',
  `enable_basic_salary` TINYINT(1) NOT NULL DEFAULT 1,
  `enable_auto_overtime` TINYINT(1) NOT NULL DEFAULT 1,
  `sessi_emp_percent` DECIMAL(8,2) NOT NULL DEFAULT 1.00,
  `sessi_org_percent` DECIMAL(8,2) NOT NULL DEFAULT 6.00,
  `pf_emp_percent` DECIMAL(8,2) NOT NULL DEFAULT 0.00,
  `pf_org_percent` DECIMAL(8,2) NOT NULL DEFAULT 0.00,
  `enable_sessi` TINYINT(1) NOT NULL DEFAULT 1,
  `enable_pf` TINYINT(1) NOT NULL DEFAULT 0,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `hr_payroll_setup` (`name`)
SELECT 'General Payroll' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM hr_payroll_setup LIMIT 1);

CREATE TABLE IF NOT EXISTS `hr_payslip_options` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `setup_id` INT UNSIGNED NOT NULL DEFAULT 1,
  `payslip_title` VARCHAR(120) NOT NULL DEFAULT 'Payslip',
  `payslip_format` VARCHAR(40) NOT NULL DEFAULT 'Standard',
  `logo_alignment` VARCHAR(20) NOT NULL DEFAULT 'Left',
  `approval_levels` TINYINT NOT NULL DEFAULT 0,
  `auto_email` TINYINT(1) NOT NULL DEFAULT 0,
  `add_signature` TINYINT(1) NOT NULL DEFAULT 1,
  `show_bank` TINYINT(1) NOT NULL DEFAULT 1,
  `show_ytd` TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `hr_payslip_options` (`setup_id`)
SELECT 1 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM hr_payslip_options LIMIT 1);

CREATE TABLE IF NOT EXISTS `hr_payroll_calendar` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `year` INT NOT NULL,
  `start_date` DATE NOT NULL,
  `end_date` DATE NOT NULL,
  `pay_periods` INT NOT NULL DEFAULT 12,
  `label` VARCHAR(80) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_cal_year` (`year`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `hr_payroll_calendar` (`year`, `start_date`, `end_date`, `pay_periods`, `label`)
SELECT 2026, '2026-01-01', '2026-12-31', 12, 'FY 2026' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM hr_payroll_calendar WHERE year = 2026);
INSERT INTO `hr_payroll_calendar` (`year`, `start_date`, `end_date`, `pay_periods`, `label`)
SELECT 2025, '2025-01-01', '2025-12-31', 12, 'FY 2025' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM hr_payroll_calendar WHERE year = 2025);

CREATE TABLE IF NOT EXISTS `hr_bank_account` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `bank_name` VARCHAR(120) NOT NULL,
  `account_title` VARCHAR(120) DEFAULT NULL,
  `account_number` VARCHAR(60) NOT NULL,
  `iban` VARCHAR(40) DEFAULT NULL,
  `branch` VARCHAR(120) DEFAULT NULL,
  `is_primary` TINYINT(1) NOT NULL DEFAULT 0,
  `status` TINYINT NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_employee_bank` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `employee_id` INT UNSIGNED NOT NULL,
  `bank_name` VARCHAR(120) NOT NULL,
  `account_number` VARCHAR(60) NOT NULL,
  `iban` VARCHAR(40) DEFAULT NULL,
  `is_primary` TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `idx_emp_bank` (`employee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Extra process columns (ignore if exist — applied via PHP migrate)
-- ALTER TABLE process_salary ADD COLUMN sessi_amount ...
-- ALTER TABLE process_salary ADD COLUMN pf_amount ...
-- ALTER TABLE process_salary ADD COLUMN overtime_amount ...

INSERT INTO `hr_payroll_item` (`code`, `name`, `category`, `calc_type`, `default_value`, `taxable`)
SELECT 'SESSI', 'SESSI Deduction', 'deduction', 'percent', 1, 0 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM hr_payroll_item WHERE code='SESSI');
INSERT INTO `hr_payroll_item` (`code`, `name`, `category`, `calc_type`, `default_value`, `taxable`)
SELECT 'PF', 'Provident Fund', 'deduction', 'percent', 0, 0 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM hr_payroll_item WHERE code='PF');
INSERT INTO `hr_payroll_item` (`code`, `name`, `category`, `calc_type`, `default_value`, `taxable`)
SELECT 'TAX', 'Income Tax', 'deduction', 'formula', 0, 0 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM hr_payroll_item WHERE code='TAX');
INSERT INTO `hr_payroll_item` (`code`, `name`, `category`, `calc_type`, `default_value`, `taxable`)
SELECT 'EOBI_E', 'EOBI Employee', 'deduction', 'fixed', 370, 0 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM hr_payroll_item WHERE code='EOBI_E');
