-- Extra WebHR-style form fields for recruitment screens
USE `hr360_demo`;

SET @c := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'hr_recruit_posts' AND COLUMN_NAME = 'details_json'
);
SET @sql := IF(@c = 0, 'ALTER TABLE `hr_recruit_posts` ADD COLUMN `details_json` JSON NULL', 'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'hr_recruit_requisitions' AND COLUMN_NAME = 'details_json'
);
SET @sql := IF(@c = 0, 'ALTER TABLE `hr_recruit_requisitions` ADD COLUMN `details_json` JSON NULL', 'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'hr_recruit_requisitions' AND COLUMN_NAME = 'reference_number'
);
SET @sql := IF(@c = 0, 'ALTER TABLE `hr_recruit_requisitions` ADD COLUMN `reference_number` VARCHAR(40) NULL', 'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
