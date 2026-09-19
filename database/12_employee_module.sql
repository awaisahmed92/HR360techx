-- Employee module extras (safe to re-run)
USE `hr360_demo`;

SET @db := DATABASE();

-- gender: 1=male, 2=female, 0/null=unset
SET @sql := (
  SELECT IF(
    COUNT(*) = 0,
    'ALTER TABLE `employee` ADD COLUMN `gender` TINYINT NULL DEFAULT NULL AFTER `status`',
    'SELECT 1'
  )
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'employee' AND COLUMN_NAME = 'gender'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- per-employee role overrides (PHP serialize, same shape as designation.rolls)
SET @sql := (
  SELECT IF(
    COUNT(*) = 0,
    'ALTER TABLE `employee` ADD COLUMN `rolls` LONGTEXT NULL AFTER `is_first_login`',
    'SELECT 1'
  )
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'employee' AND COLUMN_NAME = 'rolls'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- seed gender for demo rows if null
UPDATE `employee` SET `gender` = 1 WHERE `user_name` = 'admin' AND (`gender` IS NULL OR `gender` = 0);
UPDATE `employee` SET `gender` = 1 WHERE `user_name` = 'staff' AND (`gender` IS NULL OR `gender` = 0);
