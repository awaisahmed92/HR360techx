-- Travel form fields matching ERP screenshots
USE `hr360_demo`;

SET @db := DATABASE();

-- Extra header columns
SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE travel_request ADD COLUMN travel_type VARCHAR(100) NULL AFTER purpose',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='travel_request' AND COLUMN_NAME='travel_type');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE travel_request ADD COLUMN expected_budget DECIMAL(12,2) NULL DEFAULT 0 AFTER advance_amount',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='travel_request' AND COLUMN_NAME='expected_budget');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE travel_request ADD COLUMN actual_budget DECIMAL(12,2) NULL DEFAULT 0 AFTER expected_budget',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='travel_request' AND COLUMN_NAME='actual_budget');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

CREATE TABLE IF NOT EXISTS `travel_destination` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `travel_id` INT UNSIGNED NOT NULL,
  `place_of_visit` VARCHAR(191) NOT NULL DEFAULT '',
  `travel_mode` VARCHAR(100) DEFAULT NULL,
  `arrangement_type` VARCHAR(100) DEFAULT NULL,
  `travel_date` DATE DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_travel_destination_travel` (`travel_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
