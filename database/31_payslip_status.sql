-- Payslip cancel / reverse. Safe to re-run.
USE hr360_demo;

SET @db := DATABASE();

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `process_salary` ADD COLUMN `slip_status` VARCHAR(20) NOT NULL DEFAULT ''processed''',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='process_salary' AND COLUMN_NAME='slip_status');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
