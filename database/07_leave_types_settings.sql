-- Expand leave_type for Manage Leave Types + leave multi-level approval columns
USE hr360_demo;

SET @db := DATABASE();

-- leave_type extra columns
SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE leave_type ADD COLUMN calendar_title VARCHAR(191) NULL AFTER name',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='leave_type' AND COLUMN_NAME='calendar_title');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE leave_type ADD COLUMN reference_number VARCHAR(100) NULL AFTER calendar_title',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='leave_type' AND COLUMN_NAME='reference_number');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE leave_type ADD COLUMN category VARCHAR(50) NOT NULL DEFAULT ''Paid Leave'' AFTER reference_number',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='leave_type' AND COLUMN_NAME='category');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE leave_type ADD COLUMN duration_type VARCHAR(30) NOT NULL DEFAULT ''Days'' AFTER days',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='leave_type' AND COLUMN_NAME='duration_type');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE leave_type ADD COLUMN quota_reset TINYINT(1) NOT NULL DEFAULT 0 AFTER duration_type',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='leave_type' AND COLUMN_NAME='quota_reset');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE leave_type ADD COLUMN is_active TINYINT(1) NOT NULL DEFAULT 1 AFTER quota_reset',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='leave_type' AND COLUMN_NAME='is_active');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- leave multi-level columns
SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `leave` ADD COLUMN approval_levels TINYINT UNSIGNED NOT NULL DEFAULT 1 AFTER status',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='leave' AND COLUMN_NAME='approval_levels');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `leave` ADD COLUMN current_approval_level TINYINT UNSIGNED NOT NULL DEFAULT 1 AFTER approval_levels',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='leave' AND COLUMN_NAME='current_approval_level');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `leave` ADD COLUMN level1_approver_id INT NULL AFTER current_approval_level',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='leave' AND COLUMN_NAME='level1_approver_id');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `leave` ADD COLUMN level2_approver_id INT NULL AFTER level1_approver_id',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='leave' AND COLUMN_NAME='level2_approver_id');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `leave` ADD COLUMN level3_approver_id INT NULL AFTER level2_approver_id',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='leave' AND COLUMN_NAME='level3_approver_id');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- Leave module options toggles
CREATE TABLE IF NOT EXISTS leave_module_options (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  allow_edit_quota TINYINT(1) NOT NULL DEFAULT 0,
  carry_forward TINYINT(1) NOT NULL DEFAULT 0,
  pro_rata TINYINT(1) NOT NULL DEFAULT 0,
  show_prorated TINYINT(1) NOT NULL DEFAULT 0,
  disable_quota_deletion TINYINT(1) NOT NULL DEFAULT 0,
  create_future_quota TINYINT(1) NOT NULL DEFAULT 0,
  updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO leave_module_options (id) VALUES (1)
ON DUPLICATE KEY UPDATE id = id;

UPDATE leave_type SET category = 'Paid Leave' WHERE category IS NULL OR category = '';
