-- Extended employee fields (WebHR / PHP form parity) — safe to re-run
USE `hr360_demo`;

SET @db := DATABASE();

-- Adds one column when missing (MySQL 5.7+ compatible, no DELIMITER)
SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `personal_email` VARCHAR(191) NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='personal_email');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `salutation` VARCHAR(40) NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='salutation');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `preferred_name` VARCHAR(120) NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='preferred_name');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `nickname` VARCHAR(80) NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='nickname');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `pronoun` VARCHAR(40) NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='pronoun');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `nationality` VARCHAR(80) NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='nationality');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `race` VARCHAR(80) NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='race');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `home_phone` VARCHAR(50) NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='home_phone');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `office_phone` VARCHAR(50) NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='office_phone');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `mobile_number` VARCHAR(50) NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='mobile_number');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `emg_email` VARCHAR(191) NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='emg_email');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `passport_number` VARCHAR(80) NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='passport_number');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `passport_expiry` DATE NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='passport_expiry');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `passport_country` VARCHAR(80) NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='passport_country');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `driving_license` VARCHAR(80) NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='driving_license');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `driving_license_expiry` DATE NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='driving_license_expiry');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `ssn` VARCHAR(80) NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='ssn');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `ssn_expiry` DATE NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='ssn_expiry');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `ein` VARCHAR(80) NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='ein');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `calculated_service_date` DATE NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='calculated_service_date');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `company_id` INT UNSIGNED NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='company_id');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `division_id` INT UNSIGNED NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='division_id');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `work_shift_id` INT UNSIGNED NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='work_shift_id');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `grade` VARCHAR(80) NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='grade');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `grade_step` VARCHAR(80) NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='grade_step');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `employee_category` VARCHAR(80) NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='employee_category');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `supervisor_id` INT UNSIGNED NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='supervisor_id');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `allow_mobile_login` TINYINT(1) NOT NULL DEFAULT 0',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='allow_mobile_login');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `show_in_organogram` TINYINT(1) NOT NULL DEFAULT 1',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='show_in_organogram');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `exclude_from_reports` TINYINT(1) NOT NULL DEFAULT 0',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='exclude_from_reports');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `not_actively_working` TINYINT(1) NOT NULL DEFAULT 0',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='not_actively_working');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `not_actively_reason` VARCHAR(255) NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='not_actively_reason');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `notify_by_email` TINYINT(1) NOT NULL DEFAULT 1',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='notify_by_email');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `visa_sponsorship` VARCHAR(80) NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='visa_sponsorship');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `notes` TEXT NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='notes');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `permanent_address` VARCHAR(255) NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='permanent_address');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `permanent_city` VARCHAR(100) NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='permanent_city');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `permanent_province` VARCHAR(100) NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='permanent_province');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `permanent_postal` VARCHAR(40) NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='permanent_postal');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `permanent_country` VARCHAR(80) NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='permanent_country');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `weekday_same_as_permanent` TINYINT(1) NOT NULL DEFAULT 1',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='weekday_same_as_permanent');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `weekday_address` VARCHAR(255) NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='weekday_address');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `weekday_city` VARCHAR(100) NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='weekday_city');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `weekday_province` VARCHAR(100) NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='weekday_province');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `weekday_postal` VARCHAR(40) NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='weekday_postal');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `employee` ADD COLUMN `weekday_country` VARCHAR(80) NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='employee' AND COLUMN_NAME='weekday_country');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

CREATE TABLE IF NOT EXISTS `employee_category` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(80) NOT NULL,
  `status` TINYINT NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `employee_category` (`name`)
SELECT x.n FROM (
  SELECT 'Staff' n UNION SELECT 'Supervisor' UNION SELECT 'Manager' UNION SELECT 'Executive'
) x WHERE NOT EXISTS (SELECT 1 FROM employee_category LIMIT 1);
