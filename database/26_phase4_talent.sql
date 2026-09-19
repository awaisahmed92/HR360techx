-- Phase 4 Talent: hire link, reject, ref check, appraisal workflow stages
USE `hr360_demo`;
SET @db := DATABASE();

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `hr_candidate` ADD COLUMN `employee_id` INT UNSIGNED NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='hr_candidate' AND COLUMN_NAME='employee_id');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `hr_candidate` ADD COLUMN `ref_remarks` TEXT NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='hr_candidate' AND COLUMN_NAME='ref_remarks');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `hr_candidate` ADD COLUMN `rejected_at` TIMESTAMP NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='hr_candidate' AND COLUMN_NAME='rejected_at');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `performance_appraisal` ADD COLUMN `current_stage` VARCHAR(40) NOT NULL DEFAULT ''goal_setting''',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='performance_appraisal' AND COLUMN_NAME='current_stage');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `performance_appraisal` ADD COLUMN `finalized_at` TIMESTAMP NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='performance_appraisal' AND COLUMN_NAME='finalized_at');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `performance_appraisal` ADD COLUMN `acknowledged_at` TIMESTAMP NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='performance_appraisal' AND COLUMN_NAME='acknowledged_at');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

CREATE TABLE IF NOT EXISTS `hr_candidate_reference` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `candidate_id` INT UNSIGNED NOT NULL,
  `name` VARCHAR(120) NOT NULL,
  `company` VARCHAR(120) DEFAULT NULL,
  `phone` VARCHAR(40) DEFAULT NULL,
  `email` VARCHAR(191) DEFAULT NULL,
  `feedback` TEXT NULL,
  `passed` TINYINT(1) DEFAULT NULL COMMENT '1 pass 0 fail NULL pending',
  PRIMARY KEY (`id`),
  KEY `idx_cref_cand` (`candidate_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
