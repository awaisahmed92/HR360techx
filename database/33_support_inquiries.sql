-- Visitor support chats from the public homepages.
-- The tenant installer skips this file. It only belongs on hr360_master.
-- Safe to re-run.

USE hr360_master;

CREATE TABLE IF NOT EXISTS `support_inquiries` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `site` VARCHAR(40) NOT NULL,
  `page_url` VARCHAR(500) NULL,
  `visitor_name` VARCHAR(191) NOT NULL,
  `visitor_email` VARCHAR(191) NOT NULL,
  `message` TEXT NOT NULL,
  `chat_log` JSON NOT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_support_inquiries_site` (`site`),
  KEY `idx_support_inquiries_email` (`visitor_email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
