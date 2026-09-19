-- Timesheet multi-level columns + approval log (demo tenant)
USE hr360_demo;

CREATE TABLE IF NOT EXISTS timesheet_approval (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  timesheet_id INT UNSIGNED NOT NULL,
  level INT NOT NULL,
  designation_rule_id INT NOT NULL DEFAULT 0,
  approver_employee_id INT UNSIGNED NOT NULL,
  action VARCHAR(20) NOT NULL,
  remarks TEXT NULL,
  acted_on DATETIME NOT NULL,
  KEY idx_timesheet_id (timesheet_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET @db := DATABASE();

SET @sql := (
  SELECT IF(
    COUNT(*) = 0,
    'ALTER TABLE timesheet ADD COLUMN approval_pending_level INT NULL AFTER status',
    'SELECT 1'
  )
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'timesheet' AND COLUMN_NAME = 'approval_pending_level'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql := (
  SELECT IF(
    COUNT(*) = 0,
    'ALTER TABLE timesheet ADD COLUMN approval_levels TINYINT UNSIGNED NOT NULL DEFAULT 1 AFTER approval_pending_level',
    'SELECT 1'
  )
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'timesheet' AND COLUMN_NAME = 'approval_levels'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql := (
  SELECT IF(
    COUNT(*) = 0,
    'ALTER TABLE timesheet ADD COLUMN current_approval_level TINYINT UNSIGNED NOT NULL DEFAULT 1 AFTER approval_levels',
    'SELECT 1'
  )
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'timesheet' AND COLUMN_NAME = 'current_approval_level'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql := (
  SELECT IF(
    COUNT(*) = 0,
    'ALTER TABLE timesheet ADD COLUMN level1_approver_id INT NULL AFTER current_approval_level',
    'SELECT 1'
  )
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'timesheet' AND COLUMN_NAME = 'level1_approver_id'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql := (
  SELECT IF(
    COUNT(*) = 0,
    'ALTER TABLE timesheet ADD COLUMN level2_approver_id INT NULL AFTER level1_approver_id',
    'SELECT 1'
  )
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'timesheet' AND COLUMN_NAME = 'level2_approver_id'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql := (
  SELECT IF(
    COUNT(*) = 0,
    'ALTER TABLE timesheet ADD COLUMN level3_approver_id INT NULL AFTER level2_approver_id',
    'SELECT 1'
  )
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'timesheet' AND COLUMN_NAME = 'level3_approver_id'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
