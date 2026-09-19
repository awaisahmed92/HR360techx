-- Remaining payroll engine gaps
USE `hr360_demo`;

-- Attendance late minutes
ALTER TABLE `attendance`
  ADD COLUMN IF NOT EXISTS `late_minutes` INT NOT NULL DEFAULT 0 AFTER `total_minutes`,
  ADD COLUMN IF NOT EXISTS `status` TINYINT NOT NULL DEFAULT 1 COMMENT '1 present, 0 absent/LWP, 2 leave' AFTER `late_minutes`;

-- Employee join / exit for proration
ALTER TABLE `employee`
  ADD COLUMN IF NOT EXISTS `joining_date` DATE NULL AFTER `employee_code`,
  ADD COLUMN IF NOT EXISTS `exit_date` DATE NULL AFTER `joining_date`;

-- Loans (installment recovery)
CREATE TABLE IF NOT EXISTS `hr_loan` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `employee_id` INT UNSIGNED NOT NULL,
  `principal` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `recovered_amount` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `installment` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `start_date` DATE DEFAULT NULL,
  `status` TINYINT NOT NULL DEFAULT 0 COMMENT '0 pending, 1 active, 2 closed, 3 rejected',
  `remarks` TEXT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_loan_emp` (`employee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Arrears (one-shot addition in a month)
CREATE TABLE IF NOT EXISTS `hr_arrears` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `employee_id` INT UNSIGNED NOT NULL,
  `amount` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `for_month` CHAR(7) NOT NULL COMMENT 'YYYY-MM',
  `status` TINYINT NOT NULL DEFAULT 1 COMMENT '1 pending apply, 2 applied',
  `remarks` TEXT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_arrears_emp` (`employee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Setup flags for auto late
ALTER TABLE `hr_payroll_setup`
  ADD COLUMN IF NOT EXISTS `enable_auto_late` TINYINT(1) NOT NULL DEFAULT 1 AFTER `enable_auto_overtime`,
  ADD COLUMN IF NOT EXISTS `work_start_time` VARCHAR(8) NOT NULL DEFAULT '09:00:00' AFTER `enable_auto_late`,
  ADD COLUMN IF NOT EXISTS `late_grace_minutes` INT NOT NULL DEFAULT 15 AFTER `work_start_time`;

-- Process extra columns
ALTER TABLE `process_salary`
  ADD COLUMN IF NOT EXISTS `late_amount` DECIMAL(12,2) NOT NULL DEFAULT 0 AFTER `advance_amount`,
  ADD COLUMN IF NOT EXISTS `lwp_amount` DECIMAL(12,2) NOT NULL DEFAULT 0 AFTER `late_amount`,
  ADD COLUMN IF NOT EXISTS `loan_amount` DECIMAL(12,2) NOT NULL DEFAULT 0 AFTER `lwp_amount`,
  ADD COLUMN IF NOT EXISTS `arrears_amount` DECIMAL(12,2) NOT NULL DEFAULT 0 AFTER `loan_amount`;

INSERT INTO `hr_payroll_item` (`code`, `name`, `category`, `calc_type`, `default_value`, `taxable`)
SELECT 'LATE', 'Late Deduction', 'deduction', 'fixed', 0, 0 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM hr_payroll_item WHERE code='LATE');
INSERT INTO `hr_payroll_item` (`code`, `name`, `category`, `calc_type`, `default_value`, `taxable`)
SELECT 'LWP', 'Leave Without Pay', 'deduction', 'fixed', 0, 0 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM hr_payroll_item WHERE code='LWP');
INSERT INTO `hr_payroll_item` (`code`, `name`, `category`, `calc_type`, `default_value`, `taxable`)
SELECT 'LOAN', 'Loan Recovery', 'deduction', 'fixed', 0, 0 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM hr_payroll_item WHERE code='LOAN');
INSERT INTO `hr_payroll_item` (`code`, `name`, `category`, `calc_type`, `default_value`, `taxable`)
SELECT 'ARREARS', 'Salary Arrears', 'allowance', 'fixed', 0, 1 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM hr_payroll_item WHERE code='ARREARS');

-- Seed demo joining dates
UPDATE `employee` SET `joining_date` = '2024-01-01' WHERE `joining_date` IS NULL;
