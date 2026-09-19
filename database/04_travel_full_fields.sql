-- Expand travel_request for full form (plan §7.5)
USE `hr360_demo`;

SET @db := DATABASE();

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE travel_request ADD COLUMN contact VARCHAR(191) NULL AFTER project_id',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='travel_request' AND COLUMN_NAME='contact');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE travel_request ADD COLUMN accommodation VARCHAR(255) NULL AFTER mode_of_travel',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='travel_request' AND COLUMN_NAME='accommodation');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE travel_request ADD COLUMN other_passenger VARCHAR(255) NULL AFTER advance_amount',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='travel_request' AND COLUMN_NAME='other_passenger');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE travel_request ADD COLUMN attachment_note VARCHAR(255) NULL AFTER other_passenger',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='travel_request' AND COLUMN_NAME='attachment_note');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
