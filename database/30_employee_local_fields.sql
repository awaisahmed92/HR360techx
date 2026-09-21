-- Captured from hr360_demo on 2026-09-21 18:30
-- Local changes that no other SQL file creates. Safe to re-run.
USE hr360_demo;

SET @db := DATABASE();

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `surname` varchar(255) NULL DEFAULT NULL AFTER `rolls`',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='surname');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `father_name` varchar(255) NULL DEFAULT NULL AFTER `surname`',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='father_name');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `husband_name` varchar(255) NULL DEFAULT NULL AFTER `father_name`',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='husband_name');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `date_of_birth` date NULL DEFAULT NULL AFTER `husband_name`',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='date_of_birth');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `contact_number` varchar(30) NULL DEFAULT NULL AFTER `date_of_birth`',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='contact_number');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `religion` varchar(100) NULL DEFAULT NULL AFTER `contact_number`',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='religion');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `blood_group` varchar(10) NULL DEFAULT NULL AFTER `religion`',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='blood_group');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `marital_status` varchar(50) NULL DEFAULT NULL AFTER `blood_group`',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='marital_status');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `address` text NULL DEFAULT NULL AFTER `marital_status`',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='address');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `employee_type` int(10) unsigned NULL DEFAULT NULL AFTER `address`',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='employee_type');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `payroll_type` int(11) NULL DEFAULT NULL AFTER `employee_type`',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='payroll_type');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `probation_end_date` date NULL DEFAULT NULL AFTER `payroll_type`',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='probation_end_date');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `contract_start_date` date NULL DEFAULT NULL AFTER `probation_end_date`',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='contract_start_date');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `contract_end_date` date NULL DEFAULT NULL AFTER `contract_start_date`',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='contract_end_date');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `leaving_date` date NULL DEFAULT NULL AFTER `contract_end_date`',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='leaving_date');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `eobi` varchar(100) NULL DEFAULT NULL AFTER `leaving_date`',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='eobi');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `sessi` varchar(100) NULL DEFAULT NULL AFTER `eobi`',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='sessi');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `bnk_title` varchar(99) NULL DEFAULT NULL AFTER `sessi`',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='bnk_title');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `bnk_number` varchar(50) NULL DEFAULT NULL AFTER `bnk_title`',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='bnk_number');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `bnk_bank_id` int(10) unsigned NULL DEFAULT NULL AFTER `bnk_number`',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='bnk_bank_id');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `bnk_code` varchar(50) NULL DEFAULT NULL AFTER `bnk_bank_id`',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='bnk_code');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `bnk_address` varchar(255) NULL DEFAULT NULL AFTER `bnk_code`',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='bnk_address');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `emg_name` varchar(100) NULL DEFAULT NULL AFTER `bnk_address`',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='emg_name');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `emg_relationship` varchar(100) NULL DEFAULT NULL AFTER `emg_name`',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='emg_relationship');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `emg_phone` varchar(100) NULL DEFAULT NULL AFTER `emg_relationship`',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='emg_phone');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `emg_phone2` varchar(100) NULL DEFAULT NULL AFTER `emg_phone`',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='emg_phone2');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `fam_name` varchar(99) NULL DEFAULT NULL AFTER `emg_phone2`',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='fam_name');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `fam_relationship` varchar(99) NULL DEFAULT NULL AFTER `fam_name`',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='fam_relationship');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `fam_date_of_birth` date NULL DEFAULT NULL AFTER `fam_relationship`',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='fam_date_of_birth');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `fam_phone` varchar(99) NULL DEFAULT NULL AFTER `fam_date_of_birth`',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='fam_phone');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `total_experience` varchar(99) NULL DEFAULT NULL AFTER `fam_phone`',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='total_experience');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `created_by` int(10) unsigned NULL DEFAULT NULL AFTER `total_experience`',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='created_by');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `leave` ADD COLUMN `assigned` decimal(8,2) NOT NULL DEFAULT 0.00 AFTER `days`',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='leave' AND COLUMN_NAME='assigned');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

