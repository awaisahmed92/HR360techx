-- Marketing-site admin logins for https://360techx.com/admin.
-- The tenant installer skips this file. It only belongs on hr360_master.
-- Safe to re-run: an existing username is left unchanged.

USE hr360_master;

CREATE TABLE IF NOT EXISTS `platform_admins` (
  `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `username`      VARCHAR(100) NOT NULL,
  `password_hash` VARCHAR(255) NOT NULL,
  `created_at`    TIMESTAMP    NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_platform_admins_username` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `platform_admins` (`username`, `password_hash`)
VALUES ('admin', '$2y$10$8/xkHAzugm9cCrfeuCQskOonMtkuWDngHuUdqfqUD.Ffk7XZpvoa.')
ON DUPLICATE KEY UPDATE `username` = `username`;
