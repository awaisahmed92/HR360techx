<?php

/**
 * Production schema installer — applies every database/*.sql once, then verifies
 * required tables. If a required table is missing, that SQL file is re-applied.
 *
 * This is the single entrypoint for Coolify/Docker. Local XAMPP can run:
 *   php bootstrap-hr.php
 * or: php artisan hr360:schema
 */
$host = getenv('DB_HOST') ?: '127.0.0.1';
$port = getenv('DB_PORT') ?: '3306';
$appDb = getenv('DB_DATABASE') ?: 'hr360_production';
$appUser = getenv('DB_USERNAME') ?: 'root';
$appPass = getenv('DB_PASSWORD') ?: '';
$masterDb = getenv('DB_MASTER_DATABASE') ?: 'hr360_master';
$rootPass = getenv('DB_ROOT_PASSWORD') ?: '';

/** @var array<string, list<string>> filename => tables that must exist after apply */
$requiredTables = [
    '02_tenant_demo.sql' => ['company', 'employee', 'designation', 'department', 'leave_type', 'leave'],
    '03_phase1_self_service.sql' => ['travel_request', 'timesheet', 'attendance'],
    '06_approvals_notifications.sql' => ['approval_settings', 'notifications', 'notification_settings'],
    '07_leave_types_settings.sql' => ['leave_module_options'],
    '08_timesheet_approvals.sql' => ['timesheet_approval'],
    '09_phase2_masters.sql' => ['hr_org_division', 'hr_cost_center', 'hr_announcement', 'hr_policy', 'hr_work_shift'],
    '10_phase3_payroll.sql' => ['define_salary', 'tax', 'eobi', 'hr_payroll_item'],
    '12_employee_module.sql' => ['employee'],
    '13_payroll_setup.sql' => ['hr_payroll_setup', 'hr_payslip_options'],
    '14_remaining_phase3.sql' => ['hr_employee_pay'],
    '15_payroll_pending.sql' => ['hr_loan', 'hr_arrears'],
    '16_php_payroll_parity.sql' => ['sessi', 'provident_fund'],
    '17_employee_full.sql' => ['education', 'experience', 'degree'],
    '18_leave_threshold_assign.sql' => ['leave_threshold'],
    '19_weekly_schedule.sql' => ['hr_weekly_schedule'],
    '20_hiring_performance_mvp.sql' => ['hr_job', 'hr_candidate', 'performance_indicator', 'performance_appraisal'],
    '21_training_mvp.sql' => ['training', 'training_type', 'trainers'],
    '22_goals_termination_loan.sql' => ['termination', 'loan_application', 'performance_goal', 'performance_goal_types'],
    '23_letter.sql' => ['letter'],
    '24_ui_prefs.sql' => ['employee'],
    '25_employee_extended.sql' => ['employee_category'],
    '26_phase4_talent.sql' => ['hr_candidate'],
    '27_phase4_depth.sql' => ['performance_cycle'],
    '28_phase5_devices.sql' => ['biometric_devices', 'device_attendance'],
    '29_status_feed.sql' => ['status_posts'],
];

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
    $sql = preg_replace('/\bADD\s+COLUMN\s+IF\s+NOT\s+EXISTS\b/i', 'ADD COLUMN', $sql) ?? $sql;

    return $sql;
}

function isIgnorableSqlError(Throwable $e): bool
{
    return (bool) preg_match(
        '/Duplicate column name|Duplicate key name|already exists|1060|1061|1050|Duplicate entry/i',
        $e->getMessage()
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
            fwrite(STDERR, '[hr360-bootstrap] batch retry '.basename($path).': '.$e->getMessage()."\n");
        }
    }

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

function columnExists(PDO $conn, string $table, string $column): bool
{
    $stmt = $conn->prepare(
        'SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?'
    );
    $stmt->execute([$table, $column]);

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

    // Old login-only stub: recreate core tables from 02 if org masters missing.
    if (!tableExists($tenant, 'hr_org_division')) {
        echo "[hr360-bootstrap] incomplete schema — clearing stub core tables\n";
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

    $skip = ['01_master.sql', '11_reset_employee_passwords.sql'];
    $files = glob($sqlDir.DIRECTORY_SEPARATOR.'*.sql') ?: [];
    natcasesort($files);

    $appliedStmt = $tenant->prepare('SELECT 1 FROM `_schema_migrations` WHERE filename = ? LIMIT 1');
    $markStmt = $tenant->prepare('INSERT IGNORE INTO `_schema_migrations` (filename) VALUES (?)');
    $unmarkStmt = $tenant->prepare('DELETE FROM `_schema_migrations` WHERE filename = ?');

    // If a file was marked applied but required tables are gone, force re-apply.
    foreach ($requiredTables as $name => $tables) {
        $missing = false;
        foreach ($tables as $t) {
            if (!tableExists($tenant, $t)) {
                $missing = true;
                break;
            }
        }
        if ($missing) {
            $unmarkStmt->execute([$name]);
            echo "[hr360-bootstrap] will re-apply {$name} (required table missing)\n";
        }
    }

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

        if (isset($requiredTables[$name])) {
            foreach ($requiredTables[$name] as $t) {
                if (!tableExists($tenant, $t)) {
                    $unmarkStmt->execute([$name]);
                    throw new RuntimeException("After {$name}, table `{$t}` is still missing");
                }
            }
        }
    }

    if (!tableExists($tenant, 'employee') || !tableExists($tenant, 'hr_org_division')) {
        throw new RuntimeException('Core tables missing after schema apply');
    }

    $mustExist = [
        'termination', 'loan_application', 'letter', 'training', 'performance_indicator',
        'approval_settings', 'timesheet', 'travel_request', 'hr_job',
    ];
    $stillMissing = [];
    foreach ($mustExist as $t) {
        if (!tableExists($tenant, $t)) {
            $stillMissing[] = $t;
        }
    }
    if ($stillMissing !== []) {
        throw new RuntimeException('Schema incomplete, missing: '.implode(', ', $stillMissing));
    }

    if (!columnExists($tenant, 'employee', 'surname')) {
        $tenant->exec('ALTER TABLE `employee` ADD COLUMN `surname` VARCHAR(191) NULL AFTER `name`');
    }

    $hash = password_hash('admin', PASSWORD_BCRYPT);
    $exists = $tenant->prepare('SELECT employee_id FROM employee WHERE user_name = ? LIMIT 1');
    $exists->execute(['admin']);
    $adminId = $exists->fetchColumn();
    if ($adminId) {
        $upd = $tenant->prepare('UPDATE employee SET password = ?, status = 2, is_first_login = 0 WHERE employee_id = ?');
        $upd->execute([$hash, $adminId]);
        echo "[hr360-bootstrap] login ready: demo / admin / admin\n";
    } else {
        $ins = $tenant->prepare('INSERT INTO employee (name, surname, user_name, email, password, status, designation, employee_code, is_first_login) VALUES (?,?,?,?,?,2,1,?,0)');
        $ins->execute(['Demo', 'Admin', 'admin', 'admin@demo.local', $hash, 'EMP-0001']);
        echo "[hr360-bootstrap] created login demo / admin / admin\n";
    }

    echo "[hr360-bootstrap] schema complete\n";
} catch (Throwable $e) {
    fwrite(STDERR, '[hr360-bootstrap] '.$e->getMessage()."\n");
    exit(0);
}
