-- PHP replica parity tables (from D:\xampp\htdocs\hr\hr)
USE `hr360_demo`;

-- Formula rows (same shape as PHP payroll_setup)
CREATE TABLE IF NOT EXISTS `payroll_setup` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `event` INT UNSIGNED DEFAULT NULL,
  `target` INT UNSIGNED NOT NULL COMMENT 'payroll_item / hr_payroll_item id',
  `condition` VARCHAR(40) NOT NULL DEFAULT 'Percentage' COMMENT 'Fix|Percentage',
  `amount` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `category` VARCHAR(40) NOT NULL DEFAULT 'General' COMMENT 'General|EOBI|SESSI|Provident Fund',
  `added_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_ps_cat` (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `sessi` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `emp_amount` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `emp_percentage` DECIMAL(8,2) DEFAULT 1.00,
  `org_amount` DECIMAL(12,2) DEFAULT 0,
  `org_percentage` DECIMAL(8,2) DEFAULT 6.00,
  `description` TEXT NULL,
  `added_on` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `provident_fund` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `emp_amount` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `emp_percentage` DECIMAL(8,2) DEFAULT 0,
  `org_amount` DECIMAL(12,2) DEFAULT 0,
  `org_percentage` DECIMAL(8,2) DEFAULT 0,
  `description` TEXT NULL,
  `added_on` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `employee_settlements` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `employee` INT UNSIGNED NOT NULL,
  `date_of_joining` DATE DEFAULT NULL,
  `last_working_date` DATE DEFAULT NULL,
  `employee_pf` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `employer_pf` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `total_pf` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `gratuity_eligibility` TINYINT(1) NOT NULL DEFAULT 0,
  `gratuity_amount` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `outstanding_loan` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `loan_deduction` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `assets_returned` TINYINT(1) NOT NULL DEFAULT 0,
  `clearance_status` VARCHAR(40) DEFAULT 'Pending',
  `total_payable` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `net_payable` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `created_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_settle_emp` (`employee`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Align hr_payroll_item categories with PHP (General / EOBI / SESSI / Provident Fund)
UPDATE `hr_payroll_item` SET `category` = 'General' WHERE `category` IN ('allowance','earning','bonus','commission','adjustment') AND `code` NOT IN ('EOBI','EOBI_E','SESSI','PF','TAX');
UPDATE `hr_payroll_item` SET `category` = 'EOBI' WHERE `code` IN ('EOBI','EOBI_E');
UPDATE `hr_payroll_item` SET `category` = 'SESSI' WHERE `code` = 'SESSI';
UPDATE `hr_payroll_item` SET `category` = 'Provident Fund' WHERE `code` = 'PF';

INSERT INTO `sessi` (`emp_percentage`, `org_percentage`, `description`)
SELECT 1, 6, 'Default SESSI rates' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM sessi LIMIT 1);

INSERT INTO `provident_fund` (`emp_percentage`, `org_percentage`, `description`)
SELECT 0, 0, 'Default PF rates' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM provident_fund LIMIT 1);

-- Seed a sample General HRA formula if HRA item exists
INSERT INTO `payroll_setup` (`target`, `condition`, `amount`, `category`)
SELECT i.id, 'Percentage', 45, 'General' FROM hr_payroll_item i
WHERE i.code = 'HRA' AND NOT EXISTS (SELECT 1 FROM payroll_setup WHERE category='General' LIMIT 1);
