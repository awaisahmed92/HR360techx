<?php

/**
 * Production first-boot: master DB + tenant row + full HR schema from /database-sql.
 * Safe to re-run — each SQL file is tracked in `_schema_migrations`.
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
        PDO::MYSQL_ATTR_MULTI_STATEMENTS => true,
    ]);
}

function rewriteTenantSql(string $sql, string $appDb): string
{
    $safe = str_replace('`', '', $appDb);
    $sql = preg_replace('/CREATE\s+DATABASE\s+IF\s+NOT\s+EXISTS\s+`?hr360_demo`?[^;]*;/i', '', $sql) ?? $sql;
    $sql = preg_replace('/USE\s+`?hr360_demo`?\s*;/i', 'USE `'.$safe.'`;', $sql) ?? $sql;
    // MySQL 8.0 does not support ADD COLUMN IF NOT EXISTS — strip and let duplicate ignore handle it.
    $sql = preg_replace('/\bADD\s+COLUMN\s+IF\s+NOT\s+EXISTS\b/i', 'ADD COLUMN', $sql) ?? $sql;

    return $sql;
}

function isIgnorableSqlError(Throwable $e): bool
{
    $msg = $e->getMessage();

    return (bool) preg_match(
        '/Duplicate column name|Duplicate key name|already exists|1060|1061|1050/i',
        $msg
    );
}

function applySqlFile(PDO $conn, string $path, string $appDb): void
{
    $raw = file_get_contents($path);
    if ($raw === false) {
        throw new RuntimeException("Cannot read {$path}");
    }
    $sql = trim(rewriteTenantSql($raw, $appDb));
    if ($sql === '') {
        return;
    }

    try {
        $conn->exec($sql);

        return;
    } catch (Throwable $e) {
        if (!isIgnorableSqlError($e)) {
            // Fall through to statement-by-statement for mixed success files.
            fwrite(STDERR, '[hr360-bootstrap] batch retry '.basename($path).': '.$e->getMessage()."\n");
        }
    }

    // Strip /* */ and -- comments, then run statements one by one.
    $sql = preg_replace('/\/\*.*?\*\//s', '', $sql) ?? $sql;
    $sql = preg_replace('/^\s*--.*$/m', '', $sql) ?? $sql;
    $parts = preg_split('/;\s*[\r\n]+/', $sql) ?: [];
    foreach ($parts as $part) {
        $stmt = trim($part);
        if ($stmt === '' || strtoupper($stmt) === 'SELECT 1') {
            continue;
        }
        try {
            $conn->exec($stmt);
        } catch (Throwable $e) {
            if (isIgnorableSqlError($e)) {
                continue;
            }
            throw $e;
        }
    }
}

function tableExists(PDO $conn, string $table): bool
{
    $stmt = $conn->prepare(
        'SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ?'
    );
    $stmt->execute([$table]);

    return (int) $stmt->fetchColumn() > 0;
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
CREATE TABLE IF NOT EXISTS `_schema_migrations` (
  `filename` VARCHAR(191) NOT NULL,
  `applied_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`filename`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
SQL);

    // Old login-only bootstrap left skinny tables; CREATE IF NOT EXISTS cannot widen them.
    // If org masters are missing, wipe stubs so 02_tenant_demo.sql can create the real schema.
    if (!tableExists($tenant, 'hr_org_division')) {
        echo "[hr360-bootstrap] incomplete schema detected — resetting stub tables\n";
        $tenant->exec('SET FOREIGN_KEY_CHECKS=0');
        foreach (['employee', 'designation', 'company', 'department', 'station', 'project', 'leave', 'leave_type', 'leave_approval'] as $t) {
            $tenant->exec('DROP TABLE IF EXISTS `'.$t.'`');
        }
        $tenant->exec('SET FOREIGN_KEY_CHECKS=1');
        $tenant->exec('DELETE FROM `_schema_migrations`');
    }

    $sqlRoots = array_values(array_filter([
        getenv('HR360_SQL_DIR') ?: '',
        __DIR__.'/database-sql',
        dirname(__DIR__).'/database',
        __DIR__.'/../database',
    ]));

    $sqlDir = null;
    foreach ($sqlRoots as $dir) {
        if ($dir !== '' && is_dir($dir)) {
            $sqlDir = $dir;
            break;
        }
    }

    if ($sqlDir === null) {
        throw new RuntimeException('database SQL folder not found (expected database-sql in image)');
    }

    $skip = [
        '01_master.sql',
        '11_reset_employee_passwords.sql',
    ];

    $files = glob($sqlDir.DIRECTORY_SEPARATOR.'*.sql') ?: [];
    natcasesort($files);

    $appliedStmt = $tenant->prepare('SELECT 1 FROM `_schema_migrations` WHERE filename = ? LIMIT 1');
    $markStmt = $tenant->prepare('INSERT INTO `_schema_migrations` (filename) VALUES (?)');

    foreach ($files as $path) {
        $name = basename($path);
        if (in_array($name, $skip, true)) {
            continue;
        }
        $appliedStmt->execute([$name]);
        if ($appliedStmt->fetchColumn()) {
            continue;
        }

        echo "[hr360-bootstrap] applying {$name}\n";
        applySqlFile($tenant, $path, $appDb);
        $markStmt->execute([$name]);
    }

    if (!tableExists($tenant, 'employee')) {
        throw new RuntimeException('employee table still missing after schema apply');
    }

    if (!tableExists($tenant, 'hr_org_division')) {
        throw new RuntimeException('hr_org_division still missing — Organizations grids will fail');
    }

    // Ensure surname column used by AuthController.
    if ((int) $tenant->query("SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'employee' AND COLUMN_NAME = 'surname'")->fetchColumn() === 0) {
        $tenant->exec('ALTER TABLE `employee` ADD COLUMN `surname` VARCHAR(191) NULL AFTER `name`');
    }

    // Ensure login works with demo / admin / admin (02 seed uses admin123).
    $hash = password_hash('admin', PASSWORD_BCRYPT);
    $exists = $tenant->prepare('SELECT employee_id FROM employee WHERE user_name = ? LIMIT 1');
    $exists->execute(['admin']);
    $adminId = $exists->fetchColumn();
    if ($adminId) {
        $upd = $tenant->prepare('UPDATE employee SET password = ?, status = 2, is_first_login = 0 WHERE employee_id = ?');
        $upd->execute([$hash, $adminId]);
        echo "[hr360-bootstrap] admin password set to admin\n";
    } else {
        $ins = $tenant->prepare('INSERT INTO employee (name, surname, user_name, email, password, status, designation, employee_code, is_first_login) VALUES (?,?,?,?,?,2,1,?,0)');
        $ins->execute(['Demo', 'Admin', 'admin', 'admin@demo.local', $hash, 'EMP-0001']);
        echo "[hr360-bootstrap] created login admin / admin (org: demo)\n";
    }

    echo "[hr360-bootstrap] schema complete\n";
} catch (Throwable $e) {
    fwrite(STDERR, '[hr360-bootstrap] '.$e->getMessage()."\n");
    // Still start the API so /up works and login returns a real error.
    exit(0);
}
