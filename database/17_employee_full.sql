-- Full employee personal/job/history columns + child tables (PHP parity)
USE `hr360_demo`;

-- Helper: add column if missing
-- (run via PHP migrate script)

CREATE TABLE IF NOT EXISTS `degree` (
  `degree_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(120) NOT NULL,
  `status` TINYINT NOT NULL DEFAULT 1,
  PRIMARY KEY (`degree_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `employee_type` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(80) NOT NULL,
  `status` TINYINT NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `banklist` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(120) NOT NULL,
  `status` TINYINT NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `education` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `employee_id` INT UNSIGNED NOT NULL,
  `degree_id` INT UNSIGNED DEFAULT NULL,
  `institute` VARCHAR(191) DEFAULT NULL,
  `field` VARCHAR(191) DEFAULT NULL,
  `from` DATE DEFAULT NULL,
  `to` DATE DEFAULT NULL,
  `grade` VARCHAR(40) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_edu_emp` (`employee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `experience` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `employee_id` INT UNSIGNED NOT NULL,
  `company` VARCHAR(191) DEFAULT NULL,
  `location` VARCHAR(191) DEFAULT NULL,
  `position` VARCHAR(191) DEFAULT NULL,
  `from` DATE DEFAULT NULL,
  `to` DATE DEFAULT NULL,
  `reason` VARCHAR(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_exp_emp` (`employee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `dependents` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `employee_id` INT UNSIGNED NOT NULL,
  `name` VARCHAR(120) NOT NULL,
  `relationship` VARCHAR(80) DEFAULT NULL,
  `cnic` VARCHAR(40) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_dep_emp` (`employee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `degree` (`name`)
SELECT x.n FROM (
  SELECT 'Matric' n UNION SELECT 'Intermediate' UNION SELECT 'Bachelor' UNION SELECT 'Master' UNION SELECT 'PhD' UNION SELECT 'Diploma'
) x WHERE NOT EXISTS (SELECT 1 FROM degree LIMIT 1);

INSERT INTO `employee_type` (`name`)
SELECT x.n FROM (
  SELECT 'Permanent' n UNION SELECT 'Contract' UNION SELECT 'Intern' UNION SELECT 'Probation' UNION SELECT 'Consultant'
) x WHERE NOT EXISTS (SELECT 1 FROM employee_type LIMIT 1);

INSERT INTO `banklist` (`name`)
SELECT x.n FROM (
  SELECT 'HBL' n UNION SELECT 'UBL' UNION SELECT 'MCB' UNION SELECT 'Allied Bank' UNION SELECT 'Meezan Bank' UNION SELECT 'Bank Alfalah' UNION SELECT 'Askari Bank' UNION SELECT 'Standard Chartered'
) x WHERE NOT EXISTS (SELECT 1 FROM banklist LIMIT 1);
