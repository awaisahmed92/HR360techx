-- HR360 Flutter replica — TENANT database (demo / scfnew sample)
-- Core tables for Phase 0–1 (auth, org, leave). Expand as modules are added.

CREATE DATABASE IF NOT EXISTS `hr360_demo`
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE `hr360_demo`;

CREATE TABLE IF NOT EXISTS `company` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(191) DEFAULT NULL,
  `hr_company_name` VARCHAR(191) DEFAULT NULL,
  `code` VARCHAR(50) DEFAULT NULL,
  `email` VARCHAR(191) DEFAULT NULL,
  `currency` VARCHAR(10) DEFAULT 'PKR',
  `hr_date_format` VARCHAR(20) DEFAULT 'd-m-Y',
  `hr_logo` VARCHAR(255) DEFAULT NULL,
  `logo` VARCHAR(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `department` (
  `department_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(191) NOT NULL,
  PRIMARY KEY (`department_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `designation` (
  `designation_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(191) NOT NULL,
  `parent_designation_id` INT UNSIGNED DEFAULT NULL,
  `rolls` LONGTEXT NULL,
  PRIMARY KEY (`designation_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `station` (
  `station_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(191) NOT NULL,
  `office_type` VARCHAR(50) DEFAULT NULL,
  PRIMARY KEY (`station_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `project` (
  `project_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(191) NOT NULL,
  PRIMARY KEY (`project_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `employee` (
  `employee_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(191) NOT NULL,
  `user_name` VARCHAR(100) DEFAULT NULL,
  `email` VARCHAR(191) DEFAULT NULL,
  `password` VARCHAR(255) NOT NULL,
  `status` TINYINT NOT NULL DEFAULT 1 COMMENT '2 = admin/all access',
  `designation` INT UNSIGNED DEFAULT NULL,
  `department` INT UNSIGNED DEFAULT NULL,
  `station` INT UNSIGNED DEFAULT NULL,
  `project` INT UNSIGNED DEFAULT NULL,
  `line_manager` INT UNSIGNED DEFAULT NULL,
  `employee_code` VARCHAR(50) DEFAULT NULL,
  `profile_picture` VARCHAR(255) DEFAULT NULL,
  `is_first_login` TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`employee_id`),
  UNIQUE KEY `uq_employee_user_name` (`user_name`),
  KEY `idx_employee_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `leave_type` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(191) NOT NULL,
  `days` INT NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `leave` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `leave_type` INT UNSIGNED NOT NULL,
  `employee` INT UNSIGNED NOT NULL,
  `from` DATE NOT NULL,
  `to` DATE NOT NULL,
  `days` INT NOT NULL DEFAULT 1,
  `reason` TEXT NULL,
  `status` TINYINT NOT NULL DEFAULT 0 COMMENT '0 pending, 1 approved, 2 rejected',
  `approve_date` DATETIME DEFAULT NULL,
  `date` DATETIME DEFAULT NULL,
  `project` INT UNSIGNED DEFAULT NULL,
  `station` INT UNSIGNED DEFAULT NULL,
  `approval_pending_level` INT DEFAULT NULL,
  `added_by` INT UNSIGNED DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_leave_employee` (`employee`),
  KEY `idx_leave_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `leave_approval` (
  `leave_approval_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `leave_id` INT UNSIGNED NOT NULL,
  `level` INT NOT NULL DEFAULT 1,
  `designation_rule_id` INT DEFAULT NULL,
  `approver_employee_id` INT UNSIGNED NOT NULL,
  `action` ENUM('approve','reject') NOT NULL,
  `remarks` TEXT NULL,
  `acted_on` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`leave_approval_id`),
  KEY `idx_leave_approval_leave` (`leave_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Seed company
INSERT INTO `company` (`id`, `name`, `hr_company_name`, `code`, `email`, `currency`)
VALUES (1, 'HR360 Demo Org', 'HR360 Demo Org', 'DEMO', 'hr@demo.local', 'PKR')
ON DUPLICATE KEY UPDATE `hr_company_name` = VALUES(`hr_company_name`);

INSERT INTO `department` (`department_id`, `name`) VALUES
  (1, 'Human Resources'),
  (2, 'Operations')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

INSERT INTO `station` (`station_id`, `name`, `office_type`) VALUES
  (1, 'Head Office', 'HO')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

INSERT INTO `project` (`project_id`, `name`) VALUES
  (1, 'Core Operations')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

-- Admin designation with all-access rolls blob (PHP serialized shape, simplified)
-- rolls: module => [roll=>'1', Screen=>[view,add,edit,delete]]
INSERT INTO `designation` (`designation_id`, `name`, `rolls`) VALUES
  (1, 'HR Manager', 'a:3:{s:9:\"Dashboard\";a:2:{s:4:\"roll\";s:1:\"1\";s:14:\"AdminDashboard\";a:4:{i:0;s:1:\"1\";i:1;s:1:\"1\";i:2;s:1:\"1\";i:3;s:1:\"1\";}}s:5:\"Leave\";a:2:{s:4:\"roll\";s:1:\"1\";s:16:\"LeaveApplication\";a:4:{i:0;s:1:\"1\";i:1;s:1:\"1\";i:2;s:1:\"1\";i:3;s:1:\"1\";}}s:10:\"AdminSetup\";a:2:{s:4:\"roll\";s:1:\"1\";s:8:\"Employee\";a:4:{i:0;s:1:\"1\";i:1;s:1:\"1\";i:2;s:1:\"1\";i:3;s:1:\"1\";}}}'),
  (2, 'Staff', 'a:2:{s:9:\"Dashboard\";a:2:{s:4:\"roll\";s:1:\"1\";s:17:\"EmployeeDashboard\";a:4:{i:0;s:1:\"1\";i:1;s:1:\"0\";i:2;s:1:\"0\";i:3;s:1:\"0\";}}s:5:\"Leave\";a:2:{s:4:\"roll\";s:1:\"1\";s:16:\"LeaveApplication\";a:4:{i:0;s:1:\"1\";i:1;s:1:\"1\";i:2;s:1:\"0\";i:3;s:1:\"0\";}}}')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `rolls` = VALUES(`rolls`);

INSERT INTO `leave_type` (`id`, `name`, `days`) VALUES
  (1, 'Annual Leave', 24),
  (2, 'Sick Leave', 12),
  (3, 'Casual Leave', 6)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `days` = VALUES(`days`);

-- Passwords: admin / admin123  and  staff / staff123  (bcrypt)
INSERT INTO `employee`
  (`employee_id`, `name`, `user_name`, `email`, `password`, `status`, `designation`, `department`, `station`, `project`, `line_manager`, `employee_code`, `is_first_login`)
VALUES
  (1, 'Demo Admin', 'admin', 'admin@demo.local',
   '$2y$10$tYj9HwPVpFevxOqGghL9JOgmJLJWWSQdz4a6iSb4Ij2.dzJDVeqBa',
   2, 1, 1, 1, 1, NULL, 'EMP-001', 0),
  (2, 'Ali Staff', 'staff', 'staff@demo.local',
   '$2y$10$dIbm2kKSctc.Jy20G4hHluD3BWYLZHpp.HlvxhWSut4ZiYMj75U0e',
   1, 2, 2, 1, 1, 1, 'EMP-002', 0)
ON DUPLICATE KEY UPDATE
  `name` = VALUES(`name`),
  `password` = VALUES(`password`),
  `status` = VALUES(`status`),
  `line_manager` = VALUES(`line_manager`);
