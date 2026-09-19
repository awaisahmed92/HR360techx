-- Training MVP (PHP parity)
USE `hr360_demo`;

CREATE TABLE IF NOT EXISTS `training_type` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(191) NOT NULL,
  `category` VARCHAR(100) DEFAULT NULL,
  `renewal_months` INT DEFAULT NULL,
  `is_mandatory` TINYINT(1) NOT NULL DEFAULT 0,
  `description` TEXT NULL,
  `status` TINYINT NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `trainers` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `first_name` VARCHAR(100) NOT NULL,
  `last_name` VARCHAR(100) DEFAULT NULL,
  `role` VARCHAR(100) DEFAULT NULL,
  `internal_external` VARCHAR(20) NOT NULL DEFAULT 'internal',
  `department_id` INT UNSIGNED DEFAULT NULL,
  `email` VARCHAR(191) DEFAULT NULL,
  `phone` VARCHAR(40) DEFAULT NULL,
  `description` TEXT NULL,
  `status` TINYINT NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `training` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `training_type_id` INT UNSIGNED DEFAULT NULL,
  `trainer_id` INT UNSIGNED DEFAULT NULL,
  `employee_id` INT UNSIGNED DEFAULT NULL COMMENT 'Lead / organizer',
  `start_date` DATE DEFAULT NULL,
  `end_date` DATE DEFAULT NULL,
  `cost` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `description` TEXT NULL,
  `status` TINYINT NOT NULL DEFAULT 1,
  `venue` VARCHAR(255) DEFAULT NULL,
  `training_status` VARCHAR(30) NOT NULL DEFAULT 'Scheduled',
  `batch_name` VARCHAR(255) DEFAULT NULL,
  `agenda` TEXT NULL,
  `materials` TEXT NULL,
  `fund_source` VARCHAR(255) DEFAULT NULL,
  `cost_travel` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `cost_venue` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `cost_materials` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `cost_trainer_fee` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `is_cancelled` TINYINT(1) NOT NULL DEFAULT 0,
  `created_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_training_type` (`training_type_id`),
  KEY `idx_training_dates` (`start_date`, `end_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `training_participants` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `training_id` INT UNSIGNED NOT NULL,
  `employee_id` INT UNSIGNED NOT NULL,
  `enrollment_date` DATE DEFAULT NULL,
  `completion_date` DATE DEFAULT NULL,
  `attendance_percentage` DECIMAL(5,2) NOT NULL DEFAULT 0.00,
  `final_score` DECIMAL(5,2) DEFAULT NULL,
  `certificate_issued` TINYINT(1) NOT NULL DEFAULT 0,
  `completed` TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_training_emp` (`training_id`, `employee_id`),
  KEY `idx_tp_emp` (`employee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `training_type` (`name`, `category`, `renewal_months`, `is_mandatory`, `description`, `status`)
SELECT * FROM (
  SELECT 'Safety Induction' AS name, 'Compliance' AS category, 12 AS renewal_months, 1 AS is_mandatory, 'Mandatory safety orientation' AS description, 1 AS status
) AS tmp
WHERE NOT EXISTS (SELECT 1 FROM `training_type` LIMIT 1);

INSERT INTO `training_type` (`name`, `category`, `renewal_months`, `is_mandatory`, `description`, `status`)
SELECT 'Soft Skills', 'Development', 24, 0, 'Communication and teamwork', 1
FROM DUAL
WHERE (SELECT COUNT(*) FROM `training_type`) < 2;

INSERT INTO `trainers` (`first_name`, `last_name`, `role`, `internal_external`, `email`, `status`)
SELECT * FROM (
  SELECT 'Ayesha' AS first_name, 'Khan' AS last_name, 'Lead Trainer' AS role, 'internal' AS internal_external, 'ayesha@demo.local' AS email, 1 AS status
) AS tmp
WHERE NOT EXISTS (SELECT 1 FROM `trainers` LIMIT 1);
