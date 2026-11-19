-- Company Calendar parity tables
USE `hr360_demo`;

CREATE TABLE IF NOT EXISTS `hr_calendar_event_types` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `title` VARCHAR(255) NOT NULL,
  `color` VARCHAR(20) DEFAULT '#1E4B8C',
  `requires_approval` TINYINT NOT NULL DEFAULT 0,
  `options` JSON NULL,
  `status` TINYINT NOT NULL DEFAULT 1,
  `created_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_calendar_events` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `employee_id` INT UNSIGNED DEFAULT NULL,
  `event_type_id` INT UNSIGNED DEFAULT NULL,
  `title` VARCHAR(255) NOT NULL,
  `start_at` DATETIME NOT NULL,
  `end_at` DATETIME DEFAULT NULL,
  `all_day` TINYINT NOT NULL DEFAULT 0,
  `location` VARCHAR(255) DEFAULT NULL,
  `participants` JSON NULL,
  `description` TEXT NULL,
  `budget` DECIMAL(14,2) DEFAULT 0,
  `status` TINYINT NOT NULL DEFAULT 1 COMMENT '0 Pending 1 Approved 2 Rejected 3 Cancelled',
  `google_calendar_id` VARCHAR(120) DEFAULT NULL,
  `recurring_id` INT UNSIGNED DEFAULT NULL,
  `additional_info` JSON NULL,
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
  KEY `idx_cal_evt_start` (`start_at`),
  KEY `idx_cal_evt_emp` (`employee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_calendar_recurring` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `title` VARCHAR(255) NOT NULL,
  `dates_json` JSON NULL,
  `template_json` JSON NULL,
  `created_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_calendar_meetings` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `title` VARCHAR(255) NOT NULL,
  `agenda` VARCHAR(255) DEFAULT NULL,
  `minutes` TEXT NULL,
  `details` TEXT NULL,
  `meeting_date` DATE NOT NULL,
  `meeting_time` TIME DEFAULT NULL,
  `duration_min` SMALLINT DEFAULT 60,
  `location` VARCHAR(255) DEFAULT NULL,
  `chaired_by` INT UNSIGNED DEFAULT NULL,
  `attendee_ids` JSON NULL,
  `teams_enabled` TINYINT NOT NULL DEFAULT 0,
  `teams_join_url` VARCHAR(500) DEFAULT NULL,
  `additional_info` JSON NULL,
  `notes` TEXT NULL,
  `created_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_meet_date` (`meeting_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_calendar_feed_tokens` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `employee_id` INT UNSIGNED NOT NULL,
  `token` VARCHAR(64) NOT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `revoked_at` DATETIME DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_feed_token` (`token`),
  KEY `idx_feed_emp` (`employee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_calendar_integrations` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `provider` VARCHAR(40) NOT NULL COMMENT 'google teams',
  `employee_id` INT UNSIGNED DEFAULT NULL,
  `access_token` TEXT NULL,
  `refresh_token` TEXT NULL,
  `expires_at` DATETIME DEFAULT NULL,
  `meta_json` JSON NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_int_prov` (`provider`,`employee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_calendar_settings` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `start_of_week` TINYINT NOT NULL DEFAULT 1,
  `default_overlays` JSON NULL,
  `show_everyone` TINYINT NOT NULL DEFAULT 1,
  `google_client_id` VARCHAR(255) DEFAULT NULL,
  `google_client_secret` VARCHAR(255) DEFAULT NULL,
  `teams_tenant_id` VARCHAR(120) DEFAULT NULL,
  `teams_client_id` VARCHAR(120) DEFAULT NULL,
  `teams_client_secret` VARCHAR(255) DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `hr_calendar_event_types` (`title`, `color`, `requires_approval`, `status`)
SELECT 'Company Event', '#1E4B8C', 0, 1 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `hr_calendar_event_types` WHERE `title` = 'Company Event');

INSERT INTO `hr_calendar_event_types` (`title`, `color`, `requires_approval`, `status`)
SELECT 'Team Outing', '#0D9488', 1, 1 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `hr_calendar_event_types` WHERE `title` = 'Team Outing');

INSERT INTO `hr_calendar_settings` (`start_of_week`, `default_overlays`, `show_everyone`)
SELECT 1, JSON_ARRAY('leave','holiday','birthday','anniversary','training','interview'), 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `hr_calendar_settings` LIMIT 1);

INSERT INTO `hr_calendar_events` (`title`, `start_at`, `end_at`, `all_day`, `location`, `description`, `status`, `event_type_id`, `created_at`)
SELECT 'Annual Function', CONCAT(YEAR(CURDATE()), '-05-15 09:00:00'), CONCAT(YEAR(CURDATE()), '-05-15 17:00:00'), 1, 'HQ', 'Company annual event', 1,
  (SELECT id FROM hr_calendar_event_types WHERE title='Company Event' LIMIT 1), NOW()
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `hr_calendar_events` LIMIT 1);
