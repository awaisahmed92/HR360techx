-- Recruitment full-parity tables (WebHR-inspired, HR360 naming)
USE `hr360_demo`;

CREATE TABLE IF NOT EXISTS `hr_recruit_requisition_types` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `title` VARCHAR(255) NOT NULL,
  `approval_method` TINYINT NOT NULL DEFAULT 0,
  `status` TINYINT NOT NULL DEFAULT 1,
  `options` JSON NULL,
  `created_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_recruit_requisitions` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `type_id` INT UNSIGNED DEFAULT NULL,
  `requested_by` INT UNSIGNED DEFAULT NULL,
  `hiring_manager_id` INT UNSIGNED DEFAULT NULL,
  `department_id` INT UNSIGNED DEFAULT NULL,
  `designation_id` INT UNSIGNED DEFAULT NULL,
  `reference_number` VARCHAR(40) DEFAULT NULL,
  `job_title` VARCHAR(200) NOT NULL,
  `job_type` VARCHAR(40) DEFAULT 'Permanent',
  `vacancies` SMALLINT NOT NULL DEFAULT 1,
  `qualification` TEXT NULL,
  `experience` TEXT NULL,
  `salary_min` DECIMAL(14,2) DEFAULT NULL,
  `salary_max` DECIMAL(14,2) DEFAULT NULL,
  `description` TEXT NULL,
  `opening_date` DATE DEFAULT NULL,
  `closing_date` DATE DEFAULT NULL,
  `status` TINYINT NOT NULL DEFAULT 0 COMMENT '0 Draft 1 Pending 2 Approved 3 Rejected 4 Closed',
  `approval_levels` TINYINT NOT NULL DEFAULT 0,
  `current_approval_level` TINYINT NOT NULL DEFAULT 0,
  `level1_approver_id` INT UNSIGNED DEFAULT NULL,
  `level2_approver_id` INT UNSIGNED DEFAULT NULL,
  `level3_approver_id` INT UNSIGNED DEFAULT NULL,
  `notes` TEXT NULL,
  `created_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_req_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_recruit_posts` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `requisition_id` INT UNSIGNED DEFAULT NULL,
  `legacy_job_id` INT UNSIGNED DEFAULT NULL,
  `hiring_manager_id` INT UNSIGNED DEFAULT NULL,
  `department_id` INT UNSIGNED DEFAULT NULL,
  `designation_id` INT UNSIGNED DEFAULT NULL,
  `reference_number` VARCHAR(40) DEFAULT NULL,
  `title` VARCHAR(200) NOT NULL,
  `job_type` VARCHAR(40) DEFAULT 'Permanent',
  `job_for` TINYINT NOT NULL DEFAULT 0 COMMENT '0 External 1 Internal 2 Both',
  `vacancies` SMALLINT NOT NULL DEFAULT 1,
  `qualification` TEXT NULL,
  `experience` TEXT NULL,
  `description` TEXT NULL,
  `locations` VARCHAR(255) DEFAULT NULL,
  `publish_portal` TINYINT NOT NULL DEFAULT 1,
  `opening_date` DATE DEFAULT NULL,
  `closing_date` DATE DEFAULT NULL,
  `status` TINYINT NOT NULL DEFAULT 1 COMMENT '1 Open 2 Closed 3 Cancelled',
  `created_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_post_status` (`status`),
  KEY `idx_post_legacy` (`legacy_job_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_recruit_applications` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `candidate_id` INT UNSIGNED NOT NULL,
  `post_id` INT UNSIGNED DEFAULT NULL,
  `legacy_job_id` INT UNSIGNED DEFAULT NULL,
  `source` VARCHAR(40) DEFAULT 'manual' COMMENT 'manual portal referral ats internal',
  `stage` TINYINT NOT NULL DEFAULT 0 COMMENT 'board Stage 0-4',
  `application_stage` TINYINT NOT NULL DEFAULT 0 COMMENT 'ApplicationStage 0-9',
  `is_favorite` TINYINT NOT NULL DEFAULT 0,
  `status` TINYINT NOT NULL DEFAULT 0 COMMENT '0 Active -1 Rejected 4 Hired',
  `activity_json` JSON NULL,
  `offer_letter_id` INT UNSIGNED DEFAULT NULL,
  `referred_by` INT UNSIGNED DEFAULT NULL,
  `ats_external_id` VARCHAR(80) DEFAULT NULL,
  `checkr_status` VARCHAR(40) DEFAULT NULL,
  `notes` TEXT NULL,
  `rejected_at` DATETIME DEFAULT NULL,
  `hired_at` DATETIME DEFAULT NULL,
  `created_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_app_cand` (`candidate_id`),
  KEY `idx_app_post` (`post_id`),
  KEY `idx_app_stage` (`stage`,`application_stage`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_recruit_interview_templates` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `title` VARCHAR(255) NOT NULL,
  `questions` JSON NULL,
  `status` TINYINT NOT NULL DEFAULT 1,
  `created_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_recruit_interviews` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `application_id` INT UNSIGNED NOT NULL,
  `template_id` INT UNSIGNED DEFAULT NULL,
  `title` VARCHAR(255) DEFAULT NULL,
  `scheduled_at` DATETIME DEFAULT NULL,
  `duration_min` SMALLINT DEFAULT 60,
  `location` VARCHAR(255) DEFAULT NULL,
  `mode` VARCHAR(40) DEFAULT 'onsite' COMMENT 'onsite online phone',
  `panel_ids` JSON NULL,
  `feedback` TEXT NULL,
  `score` DECIMAL(5,2) DEFAULT NULL,
  `status` TINYINT NOT NULL DEFAULT 0 COMMENT '0 Scheduled 1 Completed 2 Cancelled',
  `created_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_int_app` (`application_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_recruit_tests` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `title` VARCHAR(255) NOT NULL,
  `description` TEXT NULL,
  `pass_score` DECIMAL(5,2) DEFAULT 50,
  `status` TINYINT NOT NULL DEFAULT 1,
  `created_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_recruit_test_questions` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `test_id` INT UNSIGNED NOT NULL,
  `question` TEXT NOT NULL,
  `options_json` JSON NULL,
  `correct_answer` VARCHAR(255) DEFAULT NULL,
  `points` DECIMAL(5,2) DEFAULT 1,
  `sort_order` INT NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_tq_test` (`test_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_recruit_test_results` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `test_id` INT UNSIGNED NOT NULL,
  `application_id` INT UNSIGNED NOT NULL,
  `score` DECIMAL(5,2) DEFAULT NULL,
  `answers_json` JSON NULL,
  `passed` TINYINT DEFAULT NULL,
  `taken_at` DATETIME DEFAULT NULL,
  `created_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_tr_app` (`application_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_recruit_evaluations` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `title` VARCHAR(255) NOT NULL,
  `criteria_json` JSON NULL,
  `status` TINYINT NOT NULL DEFAULT 1,
  `created_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_recruit_evaluation_results` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `evaluation_id` INT UNSIGNED NOT NULL,
  `application_id` INT UNSIGNED NOT NULL,
  `scores_json` JSON NULL,
  `total_score` DECIMAL(6,2) DEFAULT NULL,
  `comments` TEXT NULL,
  `evaluator_id` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_er_app` (`application_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_recruit_referrals` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `employee_id` INT UNSIGNED NOT NULL,
  `candidate_id` INT UNSIGNED DEFAULT NULL,
  `post_id` INT UNSIGNED DEFAULT NULL,
  `candidate_name` VARCHAR(191) NOT NULL,
  `candidate_email` VARCHAR(191) DEFAULT NULL,
  `candidate_phone` VARCHAR(40) DEFAULT NULL,
  `notes` TEXT NULL,
  `status` TINYINT NOT NULL DEFAULT 0 COMMENT '0 Submitted 1 Accepted 2 Hired 3 Rejected',
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_ref_emp` (`employee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_recruit_tasks` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `application_id` INT UNSIGNED DEFAULT NULL,
  `post_id` INT UNSIGNED DEFAULT NULL,
  `title` VARCHAR(255) NOT NULL,
  `assignee_id` INT UNSIGNED DEFAULT NULL,
  `due_date` DATE DEFAULT NULL,
  `status` TINYINT NOT NULL DEFAULT 0 COMMENT '0 Open 1 Done 2 Cancelled',
  `notes` TEXT NULL,
  `created_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `completed_at` DATETIME DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_recruit_candidate_skills` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `candidate_id` INT UNSIGNED NOT NULL,
  `skill` VARCHAR(120) NOT NULL,
  `level` VARCHAR(40) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_skill_cand` (`candidate_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_recruit_candidate_languages` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `candidate_id` INT UNSIGNED NOT NULL,
  `language` VARCHAR(80) NOT NULL,
  `proficiency` VARCHAR(40) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_lang_cand` (`candidate_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_recruit_inbox` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `candidate_id` INT UNSIGNED DEFAULT NULL,
  `application_id` INT UNSIGNED DEFAULT NULL,
  `subject` VARCHAR(255) DEFAULT NULL,
  `body` TEXT NULL,
  `direction` VARCHAR(20) DEFAULT 'inbound',
  `is_read` TINYINT NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_recruit_email_templates` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(191) NOT NULL,
  `subject` VARCHAR(255) DEFAULT NULL,
  `body` TEXT NULL,
  `status` TINYINT NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_recruit_ats_log` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `provider` VARCHAR(40) NOT NULL,
  `action` VARCHAR(80) NOT NULL,
  `payload` JSON NULL,
  `status` VARCHAR(40) DEFAULT 'ok',
  `message` TEXT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_recruit_portal_settings` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `enabled` TINYINT NOT NULL DEFAULT 1,
  `brand_name` VARCHAR(191) DEFAULT 'Careers',
  `welcome_text` TEXT NULL,
  `fields_json` JSON NULL,
  `resume_parse_enabled` TINYINT NOT NULL DEFAULT 0,
  `ai_base_url` VARCHAR(255) DEFAULT NULL,
  `ai_api_key` VARCHAR(255) DEFAULT NULL,
  `ats_json` JSON NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `hr_recruit_requisition_types` (`title`, `status`)
SELECT 'New Position', 1 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `hr_recruit_requisition_types` LIMIT 1);

INSERT INTO `hr_recruit_portal_settings` (`enabled`, `brand_name`, `welcome_text`, `fields_json`)
SELECT 1, 'HR360 Careers', 'Join our team. Apply to open roles below.', JSON_ARRAY('name','email','phone','resume')
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `hr_recruit_portal_settings` LIMIT 1);

-- Migrate legacy jobs → posts
INSERT INTO `hr_recruit_posts` (
  `legacy_job_id`, `department_id`, `designation_id`, `title`, `job_type`, `vacancies`,
  `qualification`, `experience`, `description`, `opening_date`, `closing_date`, `status`,
  `publish_portal`, `created_by`, `created_at`
)
SELECT
  j.`id`, j.`department_id`, j.`designation_id`, j.`title`,
  CASE j.`job_type` WHEN 1 THEN 'Full-time' WHEN 2 THEN 'Part-time' WHEN 3 THEN 'Contract' WHEN 4 THEN 'Intern' ELSE 'Temporary' END,
  j.`vacancies`, j.`qualification`, j.`experience`, j.`description`, j.`start_date`, j.`end_date`,
  CASE WHEN j.`status` = 1 THEN 1 WHEN j.`status` = 2 THEN 2 ELSE 3 END,
  1, j.`created_by`, j.`created_at`
FROM `hr_job` j
WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'hr_job')
  AND NOT EXISTS (SELECT 1 FROM `hr_recruit_posts` p WHERE p.`legacy_job_id` = j.`id`);

-- Migrate candidates → applications
INSERT INTO `hr_recruit_applications` (
  `candidate_id`, `post_id`, `legacy_job_id`, `source`, `stage`, `application_stage`, `status`,
  `notes`, `rejected_at`, `created_by`, `created_at`
)
SELECT
  c.`id`,
  (SELECT p.`id` FROM `hr_recruit_posts` p WHERE p.`legacy_job_id` = c.`job_id` LIMIT 1),
  c.`job_id`,
  'manual',
  CASE WHEN c.`status` < 0 THEN 0 ELSE LEAST(GREATEST(c.`status`, 0), 4) END,
  CASE WHEN c.`status` < 0 THEN 9 ELSE LEAST(GREATEST(c.`status`, 0), 9) END,
  CASE WHEN c.`status` < 0 THEN -1 WHEN c.`status` = 4 THEN 4 ELSE 0 END,
  c.`remarks`,
  c.`rejected_at`,
  c.`created_by`,
  c.`created_at`
FROM `hr_candidate` c
WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'hr_candidate')
  AND NOT EXISTS (SELECT 1 FROM `hr_recruit_applications` a WHERE a.`candidate_id` = c.`id`);

INSERT INTO `hr_recruit_interview_templates` (`title`, `questions`, `status`)
SELECT 'General Interview', JSON_ARRAY('Tell us about yourself', 'Why this role?', 'Expected salary?'), 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `hr_recruit_interview_templates` LIMIT 1);

INSERT INTO `hr_recruit_tests` (`title`, `description`, `pass_score`, `status`)
SELECT 'General Aptitude', 'Basic screening test', 60, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `hr_recruit_tests` LIMIT 1);

INSERT INTO `hr_recruit_test_questions` (`test_id`, `question`, `options_json`, `correct_answer`, `points`, `sort_order`)
SELECT t.`id`, 'What is 2+2?', JSON_ARRAY('3','4','5'), '4', 1, 1
FROM `hr_recruit_tests` t
WHERE t.`title` = 'General Aptitude'
  AND NOT EXISTS (SELECT 1 FROM `hr_recruit_test_questions` q WHERE q.`test_id` = t.`id` LIMIT 1);

INSERT INTO `hr_recruit_evaluations` (`title`, `criteria_json`, `status`)
SELECT 'Standard Scorecard', JSON_ARRAY(
  JSON_OBJECT('name','Communication','max',10),
  JSON_OBJECT('name','Technical','max',10),
  JSON_OBJECT('name','Culture Fit','max',10)
), 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `hr_recruit_evaluations` LIMIT 1);

INSERT INTO `hr_recruit_email_templates` (`name`, `subject`, `body`, `status`)
SELECT 'Interview Invite', 'Interview invitation', 'Dear {{candidate_name}}, please join us for an interview.', 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `hr_recruit_email_templates` LIMIT 1);
