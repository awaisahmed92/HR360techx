-- Goals + Termination + Loan Application MVP
USE `hr360_demo`;

CREATE TABLE IF NOT EXISTS `performance_goal_types` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(150) NOT NULL,
  `description` TEXT NULL,
  `status` TINYINT(1) NOT NULL DEFAULT 1,
  `created_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `performance_goal` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `employee_id` INT UNSIGNED NOT NULL,
  `goal_type_id` INT UNSIGNED DEFAULT NULL,
  `appraisal_id` INT UNSIGNED DEFAULT NULL,
  `title` VARCHAR(255) NOT NULL,
  `metric` VARCHAR(255) DEFAULT NULL,
  `weight` DECIMAL(5,2) NOT NULL DEFAULT 0.00,
  `target_value` VARCHAR(255) DEFAULT NULL,
  `achievement_value` VARCHAR(255) DEFAULT NULL,
  `score` DECIMAL(6,2) NOT NULL DEFAULT 0.00,
  `period` VARCHAR(80) DEFAULT NULL,
  `status` TINYINT NOT NULL DEFAULT 0 COMMENT '0 Active 1 Completed 2 Cancelled',
  `employee_comment` TEXT NULL,
  `manager_comment` TEXT NULL,
  `created_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_pg_emp` (`employee_id`),
  KEY `idx_pg_type` (`goal_type_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `termination` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `employee` INT UNSIGNED NOT NULL,
  `termination_type` VARCHAR(100) NOT NULL DEFAULT 'Others',
  `termination_date` DATE NOT NULL,
  `notice_date` DATE DEFAULT NULL,
  `reason` TEXT NULL,
  `created_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_term_emp` (`employee`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `loan_application` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `employee` INT UNSIGNED NOT NULL,
  `loan_amount` DECIMAL(15,2) NOT NULL DEFAULT 0.00,
  `purpose_of_loan` TEXT NULL,
  `start_date` DATE NOT NULL,
  `end_date` DATE NOT NULL,
  `status` ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending',
  `created_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_loan_emp` (`employee`),
  KEY `idx_loan_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `performance_goal_types` (`name`, `description`, `status`)
SELECT * FROM (
  SELECT 'OKR' AS name, 'Objectives and key results' AS description, 1 AS status
) AS tmp
WHERE NOT EXISTS (SELECT 1 FROM `performance_goal_types` LIMIT 1);

INSERT INTO `performance_goal_types` (`name`, `description`, `status`)
SELECT 'KPI', 'Key performance indicator', 1
FROM DUAL
WHERE (SELECT COUNT(*) FROM `performance_goal_types`) < 2;
