-- Remaining Phase 3: advance recovery tracking, auto rules, employee pay profile
USE `hr360_demo`;

-- Track how much of an advance has been recovered via payroll
SET @sql := (
  SELECT IF(COUNT(*) = 0,
    'ALTER TABLE `hr_advance` ADD COLUMN `recovered_amount` DECIMAL(12,2) NOT NULL DEFAULT 0 AFTER `amount`',
    'SELECT 1')
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'hr_advance' AND COLUMN_NAME = 'recovered_amount'
);
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

CREATE TABLE IF NOT EXISTS `hr_auto_deduction_rule` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `minutes_from` INT NOT NULL DEFAULT 0,
  `minutes_to` INT NOT NULL DEFAULT 0,
  `amount_type` VARCHAR(40) NOT NULL DEFAULT 'Specified Amount',
  `method` VARCHAR(40) NOT NULL DEFAULT 'Fixed Amount',
  `amount` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `status` TINYINT NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_auto_addition_rule` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `minutes_from` INT NOT NULL DEFAULT 0,
  `minutes_to` INT NOT NULL DEFAULT 0,
  `amount_type` VARCHAR(40) NOT NULL DEFAULT 'Specified Amount',
  `method` VARCHAR(40) NOT NULL DEFAULT 'Fixed Amount',
  `amount` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `status` TINYINT NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_employee_pay` (
  `employee_id` INT UNSIGNED NOT NULL,
  `payroll_setup` VARCHAR(80) DEFAULT 'General Payroll',
  `salary_type` VARCHAR(40) DEFAULT 'Salary',
  `currency` VARCHAR(10) DEFAULT 'PKR',
  `hours_per_week` DECIMAL(8,2) DEFAULT 0,
  `annual_salary` DECIMAL(12,2) DEFAULT 0,
  `gross_salary` DECIMAL(12,2) DEFAULT 0,
  `hourly_salary` DECIMAL(12,5) DEFAULT 0,
  `ot_hourly_salary` DECIMAL(12,5) DEFAULT 0,
  `bonus_entitlement` DECIMAL(12,2) DEFAULT 0,
  `residency_status` VARCHAR(40) DEFAULT 'Resident',
  `exclude_from_tax` TINYINT(1) NOT NULL DEFAULT 0,
  `prev_months` INT NOT NULL DEFAULT 0,
  `prev_taxable` DECIMAL(12,2) DEFAULT 0,
  `prev_tax` DECIMAL(12,2) DEFAULT 0,
  `payment_method` VARCHAR(40) DEFAULT 'Manual',
  `salary_allocation_by` VARCHAR(40) DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`employee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `hr_payroll_item` (`code`, `name`, `category`, `calc_type`, `default_value`, `taxable`)
SELECT 'ADV', 'Advance Recovery', 'deduction', 'fixed', 0, 0 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM hr_payroll_item WHERE code='ADV');

INSERT INTO `hr_payroll_setup` (`name`)
SELECT 'General Payroll' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM hr_payroll_setup LIMIT 1);
