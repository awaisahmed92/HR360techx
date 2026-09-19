-- Phase 4 depth: candidate profile children + appraisal cycles
USE `hr360_demo`;
SET @db := DATABASE();

CREATE TABLE IF NOT EXISTS `hr_candidate_education` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `candidate_id` INT UNSIGNED NOT NULL,
  `degree_id` INT UNSIGNED DEFAULT NULL,
  `institute` VARCHAR(191) DEFAULT NULL,
  `field` VARCHAR(191) DEFAULT NULL,
  `from_year` VARCHAR(20) DEFAULT NULL,
  `to_year` VARCHAR(20) DEFAULT NULL,
  `grade` VARCHAR(40) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_cedu_cand` (`candidate_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_candidate_experience` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `candidate_id` INT UNSIGNED NOT NULL,
  `company` VARCHAR(191) DEFAULT NULL,
  `position` VARCHAR(191) DEFAULT NULL,
  `from_date` VARCHAR(40) DEFAULT NULL,
  `to_date` VARCHAR(40) DEFAULT NULL,
  `location` VARCHAR(120) DEFAULT NULL,
  `reason` VARCHAR(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_cexp_cand` (`candidate_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Prefer hr_candidate_reference from 26_; ensure it exists
CREATE TABLE IF NOT EXISTS `hr_candidate_reference` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `candidate_id` INT UNSIGNED NOT NULL,
  `name` VARCHAR(120) NOT NULL,
  `company` VARCHAR(120) DEFAULT NULL,
  `designation` VARCHAR(120) DEFAULT NULL,
  `phone` VARCHAR(40) DEFAULT NULL,
  `email` VARCHAR(191) DEFAULT NULL,
  `feedback` TEXT NULL,
  `passed` TINYINT(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_cref_cand` (`candidate_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `hr_candidate_reference` ADD COLUMN `designation` VARCHAR(120) NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='hr_candidate_reference' AND COLUMN_NAME='designation');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `hr_candidate` ADD COLUMN `qualification` VARCHAR(191) NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='hr_candidate' AND COLUMN_NAME='qualification');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `hr_candidate` ADD COLUMN `district` VARCHAR(100) NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='hr_candidate' AND COLUMN_NAME='district');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

CREATE TABLE IF NOT EXISTS `performance_cycle` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(150) NOT NULL,
  `period_start` DATE DEFAULT NULL,
  `period_end` DATE DEFAULT NULL,
  `status` TINYINT NOT NULL DEFAULT 1 COMMENT '1 Open 0 Closed',
  `description` TEXT NULL,
  `created_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `performance_appraisal` ADD COLUMN `cycle_id` INT UNSIGNED NULL',
  'SELECT 1') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='performance_appraisal' AND COLUMN_NAME='cycle_id');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

INSERT INTO `performance_cycle` (`name`, `period_start`, `period_end`, `status`, `description`)
SELECT '2026 H1 Review', '2026-01-01', '2026-06-30', 1, 'First half performance cycle'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM performance_cycle LIMIT 1);
