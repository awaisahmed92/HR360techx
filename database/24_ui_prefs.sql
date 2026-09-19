-- Per-user / company UI prefs (theme, dark mode) — JSON, safe to re-run
USE `hr360_demo`;

SET @db := DATABASE();

SET @sql := (
  SELECT IF(
    COUNT(*) = 0,
    'ALTER TABLE `employee` ADD COLUMN `ui_prefs` LONGTEXT NULL',
    'SELECT 1'
  )
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'employee' AND COLUMN_NAME = 'ui_prefs'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql := (
  SELECT IF(
    COUNT(*) = 0,
    'ALTER TABLE `company` ADD COLUMN `ui_prefs` LONGTEXT NULL',
    'SELECT 1'
  )
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'company' AND COLUMN_NAME = 'ui_prefs'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
