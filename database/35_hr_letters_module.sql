-- HR Letters module: categories → designer types → issued instances
USE `hr360_demo`;

CREATE TABLE IF NOT EXISTS `hr_letter_categories` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(191) NOT NULL,
  `status` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_hr_letter_cat_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_letter_types` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `category_id` INT UNSIGNED DEFAULT NULL,
  `letter_kind` TINYINT NOT NULL DEFAULT 0 COMMENT '0 Employee 1 Job Candidate',
  `name` VARCHAR(255) NOT NULL,
  `contents` LONGTEXT NULL,
  `header_html` LONGTEXT NULL,
  `footer_html` LONGTEXT NULL,
  `custom_variables` JSON NULL,
  `options` JSON NULL,
  `employees_access` JSON NULL,
  `logo_path` VARCHAR(255) DEFAULT NULL,
  `footer_image_path` VARCHAR(255) DEFAULT NULL,
  `reference_pattern` VARCHAR(80) DEFAULT NULL,
  `status` TINYINT(1) NOT NULL DEFAULT 1,
  `created_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_hr_letter_types_cat` (`category_id`),
  KEY `idx_hr_letter_types_kind` (`letter_kind`),
  KEY `idx_hr_letter_types_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hr_letter_instances` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `type_id` INT UNSIGNED NOT NULL,
  `employee_id` INT UNSIGNED DEFAULT NULL,
  `candidate_id` INT UNSIGNED DEFAULT NULL,
  `name` VARCHAR(255) NOT NULL,
  `reference_number` VARCHAR(80) DEFAULT NULL,
  `contents` LONGTEXT NULL,
  `header_html` LONGTEXT NULL,
  `footer_html` LONGTEXT NULL,
  `letter_data` JSON NULL,
  `options` JSON NULL,
  `status` TINYINT NOT NULL DEFAULT 0 COMMENT '0 Pending 1 Approved 2 Rejected',
  `approval_levels` TINYINT NOT NULL DEFAULT 0,
  `current_approval_level` TINYINT NOT NULL DEFAULT 0,
  `approval_pending_level` TINYINT DEFAULT NULL,
  `level1_approver_id` INT UNSIGNED DEFAULT NULL,
  `level2_approver_id` INT UNSIGNED DEFAULT NULL,
  `level3_approver_id` INT UNSIGNED DEFAULT NULL,
  `acknowledged_at` DATETIME DEFAULT NULL,
  `acknowledged_by` INT UNSIGNED DEFAULT NULL,
  `ack_note` VARCHAR(500) DEFAULT NULL,
  `created_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_hr_letter_inst_type` (`type_id`),
  KEY `idx_hr_letter_inst_emp` (`employee_id`),
  KEY `idx_hr_letter_inst_cand` (`candidate_id`),
  KEY `idx_hr_letter_inst_status` (`status`),
  KEY `idx_hr_letter_inst_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `hr_letter_categories` (`name`, `status`)
SELECT 'General', 1 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `hr_letter_categories` WHERE `name` = 'General');

INSERT INTO `hr_letter_categories` (`name`, `status`)
SELECT 'Employment', 1 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `hr_letter_categories` WHERE `name` = 'Employment');

INSERT INTO `hr_letter_categories` (`name`, `status`)
SELECT 'Recruitment', 1 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `hr_letter_categories` WHERE `name` = 'Recruitment');

-- Migrate legacy letter templates into designer types (once).
INSERT INTO `hr_letter_types` (
  `category_id`, `letter_kind`, `name`, `contents`, `header_html`, `footer_html`,
  `custom_variables`, `options`, `status`, `created_by`, `created_at`
)
SELECT
  (SELECT `id` FROM `hr_letter_categories` WHERE `name` = 'Employment' LIMIT 1),
  0,
  l.`name`,
  REPLACE(COALESCE(l.`content`, ''), '\n', '<br>'),
  NULL,
  NULL,
  JSON_ARRAY(),
  JSON_OBJECT(
    'page_size', COALESCE(l.`page_size`, 'A4'),
    'margin_top', COALESCE(l.`margin_top`, 20),
    'margin_right', COALESCE(l.`margin_right`, 20),
    'margin_bottom', COALESCE(l.`margin_bottom`, 20),
    'margin_left', COALESCE(l.`margin_left`, 20),
    'skip_approval', false,
    'logo_align', 'left'
  ),
  COALESCE(l.`status`, 1),
  l.`created_by`,
  COALESCE(l.`created_at`, NOW())
FROM `letter` l
WHERE EXISTS (SELECT 1 FROM information_schema.tables
              WHERE table_schema = DATABASE() AND table_name = 'letter')
  AND NOT EXISTS (
    SELECT 1 FROM `hr_letter_types` t WHERE t.`name` = l.`name`
  );

-- Seed defaults when no legacy templates exist.
INSERT INTO `hr_letter_types` (
  `category_id`, `letter_kind`, `name`, `contents`, `custom_variables`, `options`, `status`
)
SELECT
  (SELECT `id` FROM `hr_letter_categories` WHERE `name` = 'Employment' LIMIT 1),
  0,
  'Experience Certificate',
  'This is to certify that {{employee_name}} ({{employee_code}}) worked with us as {{designation}} in {{department}} from {{joining_date}} to {{leaving_date}}.<br><br>We found them sincere and hardworking.<br><br>For {{company_name}}',
  JSON_ARRAY(),
  JSON_OBJECT('page_size','A4','margin_top',20,'margin_right',20,'margin_bottom',20,'margin_left',20,'skip_approval',false,'logo_align','left'),
  1
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `hr_letter_types` LIMIT 1);

INSERT INTO `hr_letter_types` (
  `category_id`, `letter_kind`, `name`, `contents`, `custom_variables`, `options`, `status`
)
SELECT
  (SELECT `id` FROM `hr_letter_categories` WHERE `name` = 'Employment' LIMIT 1),
  0,
  'Confirmation Letter',
  'Dear {{employee_name}},<br><br>We are pleased to confirm your employment as {{designation}} effective {{joining_date}}.<br><br>Regards,<br>HR Department',
  JSON_ARRAY(),
  JSON_OBJECT('page_size','A4','margin_top',20,'margin_right',20,'margin_bottom',20,'margin_left',20,'skip_approval',false,'logo_align','left'),
  1
FROM DUAL
WHERE (SELECT COUNT(*) FROM `hr_letter_types`) < 2;
