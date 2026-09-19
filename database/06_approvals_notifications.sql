-- Multi-level approvals + in-app notifications (tenant DB: hr360_demo)
USE hr360_demo;

CREATE TABLE IF NOT EXISTS approval_settings (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  module VARCHAR(50) NOT NULL,
  approval_method VARCHAR(50) NOT NULL DEFAULT 'multi_level',
  approval_levels TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '0=auto, 1-5 levels',
  restart_on_edit TINYINT(1) NOT NULL DEFAULT 0,
  skip_specific TINYINT(1) NOT NULL DEFAULT 0,
  hide_rejected TINYINT(1) NOT NULL DEFAULT 0,
  do_not_notify_employee TINYINT(1) NOT NULL DEFAULT 0,
  sms_on_submission TINYINT(1) NOT NULL DEFAULT 0,
  updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_module (module)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS approval_level_assignee (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  module VARCHAR(50) NOT NULL,
  level TINYINT UNSIGNED NOT NULL,
  employee_id INT NOT NULL,
  UNIQUE KEY uq_module_level (module, level),
  KEY idx_emp (employee_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS notification_settings (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  module VARCHAR(50) NOT NULL,
  notify_on_submission TEXT NULL COMMENT 'CSV employee ids',
  notify_on_approval TEXT NULL,
  notify_on_reassignment TEXT NULL,
  updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_notif_module (module)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS notifications (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  employee_id INT NOT NULL,
  title VARCHAR(191) NOT NULL,
  body TEXT NULL,
  kind VARCHAR(50) NOT NULL DEFAULT 'approval',
  ref_type VARCHAR(50) NULL,
  ref_id INT NULL,
  level TINYINT UNSIGNED NULL,
  is_read TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_emp_read (employee_id, is_read),
  KEY idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS travel_approval_log (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  travel_id INT NOT NULL,
  level TINYINT UNSIGNED NOT NULL,
  action VARCHAR(20) NOT NULL,
  approver_id INT NOT NULL,
  remarks VARCHAR(500) NULL,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_travel (travel_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Travel request multi-level columns (safe if re-run)
SET @db := DATABASE();

SET @sql := (
  SELECT IF(
    COUNT(*) = 0,
    'ALTER TABLE travel_request ADD COLUMN approval_levels TINYINT UNSIGNED NOT NULL DEFAULT 1 AFTER status',
    'SELECT 1'
  )
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'travel_request' AND COLUMN_NAME = 'approval_levels'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql := (
  SELECT IF(
    COUNT(*) = 0,
    'ALTER TABLE travel_request ADD COLUMN current_approval_level TINYINT UNSIGNED NOT NULL DEFAULT 1 AFTER approval_levels',
    'SELECT 1'
  )
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'travel_request' AND COLUMN_NAME = 'current_approval_level'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql := (
  SELECT IF(
    COUNT(*) = 0,
    'ALTER TABLE travel_request ADD COLUMN level1_approver_id INT NULL AFTER current_approval_level',
    'SELECT 1'
  )
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'travel_request' AND COLUMN_NAME = 'level1_approver_id'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql := (
  SELECT IF(
    COUNT(*) = 0,
    'ALTER TABLE travel_request ADD COLUMN level2_approver_id INT NULL AFTER level1_approver_id',
    'SELECT 1'
  )
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'travel_request' AND COLUMN_NAME = 'level2_approver_id'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql := (
  SELECT IF(
    COUNT(*) = 0,
    'ALTER TABLE travel_request ADD COLUMN level3_approver_id INT NULL AFTER level2_approver_id',
    'SELECT 1'
  )
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'travel_request' AND COLUMN_NAME = 'level3_approver_id'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

INSERT INTO approval_settings (module, approval_method, approval_levels)
VALUES ('travel', 'multi_level', 2), ('leave', 'multi_level', 1), ('timesheet', 'multi_level', 1)
ON DUPLICATE KEY UPDATE module = module;

INSERT INTO notification_settings (module)
VALUES ('travel'), ('leave'), ('timesheet')
ON DUPLICATE KEY UPDATE module = module;
