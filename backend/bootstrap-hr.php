<?php

/**
 * First-boot schema for production Docker MySQL.
 * Creates hr360_master (if root password is available), tenants row "demo",
 * and a tenant admin so login is not a blank 500.
 */
$host = getenv('DB_HOST') ?: '127.0.0.1';
$port = getenv('DB_PORT') ?: '3306';
$appDb = getenv('DB_DATABASE') ?: 'hr360_production';
$appUser = getenv('DB_USERNAME') ?: 'root';
$appPass = getenv('DB_PASSWORD') ?: '';
$masterDb = getenv('DB_MASTER_DATABASE') ?: 'hr360_master';
$rootPass = getenv('DB_ROOT_PASSWORD') ?: '';

function pdo(string $host, string $port, string $user, string $pass, ?string $db = null): PDO
{
    $dsn = "mysql:host={$host};port={$port};charset=utf8mb4";
    if ($db) {
        $dsn .= ";dbname={$db}";
    }
    return new PDO($dsn, $user, $pass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    ]);
}

try {
    if ($rootPass !== '') {
        $root = pdo($host, $port, 'root', $rootPass);
        $root->exec('CREATE DATABASE IF NOT EXISTS `'.str_replace('`', '', $masterDb).'` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci');
        $root->exec('CREATE DATABASE IF NOT EXISTS `'.str_replace('`', '', $appDb).'` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci');
        $safeUser = str_replace(['`', "'"], '', $appUser);
        $root->exec("GRANT ALL PRIVILEGES ON `".str_replace('`', '', $masterDb)."`.* TO '{$safeUser}'@'%'");
        $root->exec("GRANT ALL PRIVILEGES ON `".str_replace('`', '', $appDb)."`.* TO '{$safeUser}'@'%'");
        $root->exec('FLUSH PRIVILEGES');
        echo "[hr360-bootstrap] databases ready\n";
    }

    $master = pdo($host, $port, $appUser, $appPass, $masterDb);
    $master->exec(<<<'SQL'
CREATE TABLE IF NOT EXISTS `tenants` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(191) NOT NULL,
  `subdomain` VARCHAR(100) NOT NULL,
  `db_host` VARCHAR(191) NOT NULL DEFAULT 'db',
  `db_name` VARCHAR(191) NOT NULL,
  `db_user` VARCHAR(191) NOT NULL DEFAULT 'root',
  `db_password` VARCHAR(191) NOT NULL DEFAULT '',
  `status` ENUM('active','inactive','suspended') NOT NULL DEFAULT 'active',
  `hr_app` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tenants_subdomain` (`subdomain`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
SQL);

    $stmt = $master->prepare(<<<'SQL'
INSERT INTO tenants (name, subdomain, db_host, db_name, db_user, db_password, status, hr_app)
VALUES ('HR360 Demo Org', 'demo', :host, :db, :user, :pass, 'active', 1)
ON DUPLICATE KEY UPDATE
  db_host = VALUES(db_host),
  db_name = VALUES(db_name),
  db_user = VALUES(db_user),
  db_password = VALUES(db_password),
  status = 'active',
  hr_app = 1
SQL);
    $stmt->execute([
        'host' => $host,
        'db' => $appDb,
        'user' => $appUser,
        'pass' => $appPass,
    ]);
    echo "[hr360-bootstrap] tenant demo → {$appDb}@{$host}\n";

    $tenant = pdo($host, $port, $appUser, $appPass, $appDb);
    $tenant->exec(<<<'SQL'
CREATE TABLE IF NOT EXISTS `company` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(191) DEFAULT NULL,
  `hr_company_name` VARCHAR(191) DEFAULT NULL,
  `code` VARCHAR(50) DEFAULT NULL,
  `email` VARCHAR(191) DEFAULT NULL,
  `currency` VARCHAR(10) DEFAULT 'PKR',
  `hr_date_format` VARCHAR(20) DEFAULT 'd-m-Y',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB
SQL);
    $tenant->exec(<<<'SQL'
CREATE TABLE IF NOT EXISTS `designation` (
  `designation_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(191) NOT NULL,
  `rolls` LONGTEXT NULL,
  PRIMARY KEY (`designation_id`)
) ENGINE=InnoDB
SQL);
    $tenant->exec(<<<'SQL'
CREATE TABLE IF NOT EXISTS `employee` (
  `employee_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(191) NOT NULL,
  `surname` VARCHAR(191) DEFAULT NULL,
  `user_name` VARCHAR(100) DEFAULT NULL,
  `email` VARCHAR(191) DEFAULT NULL,
  `password` VARCHAR(255) NOT NULL,
  `status` TINYINT NOT NULL DEFAULT 1,
  `designation` INT UNSIGNED DEFAULT NULL,
  `employee_code` VARCHAR(50) DEFAULT NULL,
  `is_first_login` TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`employee_id`),
  UNIQUE KEY `uq_employee_user_name` (`user_name`)
) ENGINE=InnoDB
SQL);

    $count = (int) $tenant->query('SELECT COUNT(*) FROM company')->fetchColumn();
    if ($count === 0) {
        $tenant->exec("INSERT INTO company (name, hr_company_name, code, email, currency) VALUES ('HR360 Demo Org', 'HR360 Demo Org', 'DEMO', 'hr@demo.local', 'PKR')");
    }
    $dcount = (int) $tenant->query('SELECT COUNT(*) FROM designation')->fetchColumn();
    if ($dcount === 0) {
        $tenant->exec("INSERT INTO designation (name) VALUES ('HR Manager')");
    }

    $hash = password_hash('admin', PASSWORD_BCRYPT);
    $exists = $tenant->prepare('SELECT employee_id FROM employee WHERE user_name = ? LIMIT 1');
    $exists->execute(['admin']);
    if (!$exists->fetchColumn()) {
        $ins = $tenant->prepare('INSERT INTO employee (name, surname, user_name, email, password, status, designation, employee_code, is_first_login) VALUES (?,?,?,?,?,2,1,?,0)');
        $ins->execute(['Demo', 'Admin', 'admin', 'admin@demo.local', $hash, 'EMP-0001']);
        echo "[hr360-bootstrap] created login admin / admin (org: demo)\n";
    } else {
        echo "[hr360-bootstrap] admin user already exists\n";
    }
} catch (Throwable $e) {
    fwrite(STDERR, '[hr360-bootstrap] '.$e->getMessage()."\n");
    exit(0);
}
