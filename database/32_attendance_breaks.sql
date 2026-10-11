-- Lunch and extra break times on attendance. Safe to re-run.
USE hr360_demo;

SET @db := DATABASE();

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `attendance` ADD COLUMN `lunch_out` DATETIME NULL',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='attendance' AND COLUMN_NAME='lunch_out');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `attendance` ADD COLUMN `lunch_in` DATETIME NULL',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='attendance' AND COLUMN_NAME='lunch_in');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `attendance` ADD COLUMN `extra_out` DATETIME NULL',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='attendance' AND COLUMN_NAME='extra_out');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `attendance` ADD COLUMN `extra_in` DATETIME NULL',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='attendance' AND COLUMN_NAME='extra_in');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
