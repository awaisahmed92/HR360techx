-- Hiring + Performance MVP (PHP parity, simplified)
USE `hr360_demo`;

CREATE TABLE IF NOT EXISTS `hr_job` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `title` VARCHAR(191) NOT NULL,
  `designation_id` INT UNSIGNED DEFAULT NULL,
  `department_id` INT UNSIGNED DEFAULT NULL,
  `vacancies` INT NOT NULL DEFAULT 1,
  `job_type` TINYINT NOT NULL DEFAULT 1 COMMENT '1 Full-time 2 Part-time 3 Contract 4 Intern 5 Temporary',
  `experience` VARCHAR(80) DEFAULT NULL,
  `qualification` VARCHAR(191) DEFAULT NULL,
  `description` TEXT NULL,
  `start_date` DATE DEFAULT NULL,
  `end_date` DATE DEFAULT NULL,
  `status` TINYINT NOT NULL DEFAULT 1 COMMENT '1 Open 2 Closed 3 Cancelled',
  `created_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_candidate` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(191) NOT NULL,
  `email` VARCHAR(191) DEFAULT NULL,
  `phone` VARCHAR(40) DEFAULT NULL,
  `cnic` VARCHAR(40) DEFAULT NULL,
  `gender` TINYINT DEFAULT NULL,
  `job_id` INT UNSIGNED DEFAULT NULL,
  `total_experience` VARCHAR(40) DEFAULT NULL,
  `expected_salary` DECIMAL(12,2) DEFAULT NULL,
  `resume` VARCHAR(255) DEFAULT NULL,
  `status` TINYINT NOT NULL DEFAULT 0 COMMENT '0 Applied 1 Screening 2 Interview 3 Offer 4 Hired',
  `remarks` TEXT NULL,
  `created_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_cand_job` (`job_id`),
  KEY `idx_cand_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `performance_indicator` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(191) NOT NULL,
  `designation_id` INT UNSIGNED DEFAULT NULL,
  `department_id` INT UNSIGNED DEFAULT NULL,
  `description` TEXT NULL,
  `status` TINYINT NOT NULL DEFAULT 1,
  `created_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `performance_review` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `employee_id` INT UNSIGNED NOT NULL,
  `indicator_id` INT UNSIGNED DEFAULT NULL,
  `review_date` DATE DEFAULT NULL,
  `rating` DECIMAL(4,2) NOT NULL DEFAULT 0,
  `comments` TEXT NULL,
  `reviewer_id` INT UNSIGNED DEFAULT NULL,
  `status` TINYINT NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_pr_emp` (`employee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `performance_appraisal` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `employee_id` INT UNSIGNED NOT NULL,
  `manager_id` INT UNSIGNED DEFAULT NULL,
  `period` VARCHAR(80) DEFAULT NULL,
  `overall_score` DECIMAL(5,2) DEFAULT NULL,
  `final_rating` VARCHAR(40) DEFAULT NULL,
  `self_comments` TEXT NULL,
  `manager_comments` TEXT NULL,
  `status` TINYINT NOT NULL DEFAULT 0 COMMENT '0 Draft 1 In Progress 2 Completed',
  `created_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_pa_emp` (`employee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `hr_job` (`title`, `vacancies`, `job_type`, `experience`, `qualification`, `status`, `description`)
SELECT 'Software Engineer', 2, 1, '2-4 years', 'BS CS', 1, 'Flutter / Laravel development'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM hr_job LIMIT 1);

INSERT INTO `hr_job` (`title`, `vacancies`, `job_type`, `experience`, `qualification`, `status`, `description`)
SELECT 'HR Officer', 1, 1, '1-3 years', 'MBA HR', 1, 'Employee relations and payroll support'
FROM DUAL WHERE (SELECT COUNT(*) FROM hr_job) < 2;

INSERT INTO `performance_indicator` (`name`, `description`, `status`)
SELECT 'Quality of Work', 'Accuracy and thoroughness', 1 FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM performance_indicator LIMIT 1);

INSERT INTO `performance_indicator` (`name`, `description`, `status`)
SELECT 'Teamwork', 'Collaboration and communication', 1 FROM DUAL WHERE (SELECT COUNT(*) FROM performance_indicator) < 2;

INSERT INTO `performance_indicator` (`name`, `description`, `status`)
SELECT 'Punctuality', 'Attendance and time management', 1 FROM DUAL WHERE (SELECT COUNT(*) FROM performance_indicator) < 3;
