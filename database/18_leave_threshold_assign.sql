-- Leave threshold + per-employee assign quota (PHP parity)
USE `hr360_demo`;

CREATE TABLE IF NOT EXISTS `leave_threshold` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `designation_id` INT UNSIGNED NOT NULL,
  `leave_type_id` VARCHAR(255) NOT NULL COMMENT 'CSV of leave_type ids',
  `threshold_from` INT NOT NULL DEFAULT 0,
  `threshold_to` INT NOT NULL DEFAULT 0,
  `status` TINYINT NOT NULL DEFAULT 1,
  `created_by` INT UNSIGNED DEFAULT NULL,
  `updated_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_lt_desig` (`designation_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
