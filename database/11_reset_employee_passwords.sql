-- Reset ALL employee passwords in the tenant DB to "admin"
--
-- Encryption: bcrypt ($2y$…) via PHP password_hash / Laravel Hash::make
-- Auth also accepts legacy plain-text and md5 for migration, but new hashes are bcrypt.
--
-- Prefer regenerating a fresh hash (bcrypt salt changes every run):
--   php -r "echo password_hash('admin', PASSWORD_BCRYPT);"
-- then paste into the UPDATE below.
--
-- Or run once:
--   php database/_reset_passwords.php
--
-- After this: login with Organization=demo, Employee ID=admin (or staff), Password=admin

USE `hr360_demo`;

UPDATE `employee`
SET `password` = '$2y$10$ayborxhj8m5ddaKCOu8eLOsP4id.HePLVq8.Q6M9jMAzA3VTzfSmK',
    `is_first_login` = 0
WHERE `employee_id` > 0;

SELECT employee_id, user_name, name, LEFT(password, 7) AS hash_algo FROM employee;
