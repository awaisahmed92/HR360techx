-- HR Letters templates
USE `hr360_demo`;

CREATE TABLE IF NOT EXISTS `letter` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255) NOT NULL,
  `content` TEXT NULL,
  `page_size` VARCHAR(32) NOT NULL DEFAULT 'A4',
  `margin_top` DECIMAL(6,2) NOT NULL DEFAULT 20.00,
  `margin_right` DECIMAL(6,2) NOT NULL DEFAULT 20.00,
  `margin_bottom` DECIMAL(6,2) NOT NULL DEFAULT 20.00,
  `margin_left` DECIMAL(6,2) NOT NULL DEFAULT 20.00,
  `status` TINYINT(1) NOT NULL DEFAULT 1,
  `created_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `letter` (`name`, `content`, `page_size`, `status`)
SELECT * FROM (
  SELECT
    'Experience Certificate' AS name,
    'This is to certify that {{employee_name}} ({{employee_code}}) worked with us as {{designation}} in {{department}} from {{joining_date}} to {{leaving_date}}.\n\nWe found them sincere and hardworking.\n\nFor {{company_name}}' AS content,
    'A4' AS page_size,
    1 AS status
) AS tmp
WHERE NOT EXISTS (SELECT 1 FROM `letter` LIMIT 1);

INSERT INTO `letter` (`name`, `content`, `page_size`, `status`)
SELECT 'Confirmation Letter',
  'Dear {{employee_name}},\n\nWe are pleased to confirm your employment as {{designation}} effective {{joining_date}}.\n\nRegards,\nHR Department',
  'A4', 1
FROM DUAL
WHERE (SELECT COUNT(*) FROM `letter`) < 2;
