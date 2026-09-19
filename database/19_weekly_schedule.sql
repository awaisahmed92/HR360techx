-- Weekly org schedule (PHP schedule table parity)
USE `hr360_demo`;

CREATE TABLE IF NOT EXISTS `hr_weekly_schedule` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `day` VARCHAR(20) NOT NULL,
  `start_time` TIME DEFAULT '09:00:00',
  `end_time` TIME DEFAULT '18:00:00',
  `break_minutes` INT NOT NULL DEFAULT 60,
  `is_off_day` TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_day` (`day`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `hr_weekly_schedule` (`day`, `start_time`, `end_time`, `break_minutes`, `is_off_day`)
SELECT * FROM (
  SELECT 'Monday' d, '09:00:00' s, '18:00:00' e, 60 b, 0 o UNION ALL
  SELECT 'Tuesday', '09:00:00', '18:00:00', 60, 0 UNION ALL
  SELECT 'Wednesday', '09:00:00', '18:00:00', 60, 0 UNION ALL
  SELECT 'Thursday', '09:00:00', '18:00:00', 60, 0 UNION ALL
  SELECT 'Friday', '09:00:00', '18:00:00', 60, 0 UNION ALL
  SELECT 'Saturday', '09:00:00', '14:00:00', 30, 0 UNION ALL
  SELECT 'Sunday', '00:00:00', '00:00:00', 0, 1
) x WHERE NOT EXISTS (SELECT 1 FROM hr_weekly_schedule LIMIT 1);
