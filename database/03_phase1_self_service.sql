-- Phase 1 self-service tables (HR360techx only)
USE `hr360_demo`;

CREATE TABLE IF NOT EXISTS `attendance` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `employee_id` INT UNSIGNED NOT NULL,
  `date` DATE NOT NULL,
  `punch_in` DATETIME DEFAULT NULL,
  `punch_out` DATETIME DEFAULT NULL,
  `total_minutes` INT DEFAULT NULL,
  `notes` VARCHAR(255) DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_attendance_emp_date` (`employee_id`, `date`),
  KEY `idx_attendance_date` (`date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `travel_request` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `request_no` VARCHAR(30) NOT NULL,
  `employee_id` INT UNSIGNED NOT NULL,
  `project_id` INT UNSIGNED DEFAULT NULL,
  `start_date` DATE NOT NULL,
  `end_date` DATE NOT NULL,
  `from_location` VARCHAR(191) NOT NULL,
  `to_location` VARCHAR(191) NOT NULL,
  `mode_of_travel` VARCHAR(100) DEFAULT NULL,
  `purpose` TEXT NULL,
  `advance_amount` DECIMAL(12,2) DEFAULT 0,
  `status` TINYINT NOT NULL DEFAULT 0 COMMENT '0 pending, 1 approved, 2 rejected',
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_travel_request_no` (`request_no`),
  KEY `idx_travel_employee` (`employee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `timesheet` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `employee_id` INT UNSIGNED NOT NULL,
  `project_id` INT UNSIGNED NOT NULL,
  `from_date` DATE NOT NULL,
  `to_date` DATE NOT NULL,
  `hours` DECIMAL(8,2) NOT NULL DEFAULT 0,
  `description` TEXT NULL,
  `status` TINYINT NOT NULL DEFAULT 0 COMMENT '0 pending, 1 approved, 2 rejected',
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_timesheet_employee` (`employee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Optional profile fields (ignore errors if already exist when re-run)
SET @db := DATABASE();
SET @sql := (
  SELECT IF(
    COUNT(*) = 0,
    'ALTER TABLE employee ADD COLUMN phone VARCHAR(50) DEFAULT NULL AFTER email',
    'SELECT 1'
  )
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'employee' AND COLUMN_NAME = 'phone'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql := (
  SELECT IF(
    COUNT(*) = 0,
    'ALTER TABLE employee ADD COLUMN cnic VARCHAR(30) DEFAULT NULL AFTER phone',
    'SELECT 1'
  )
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'employee' AND COLUMN_NAME = 'cnic'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
