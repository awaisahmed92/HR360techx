<?php

/**
 * HR360 schema installer — single source of truth for local + production.
 *
 * Expectations are derived from the SQL files themselves:
 *   CREATE TABLE x        → table `x` must exist afterwards
 *   ALTER TABLE x ADD COLUMN y → column `x.y` must exist afterwards
 * A file is re-applied whenever it is new, its contents changed, or anything
 * it should have created is missing. Nothing to register by hand.
 *
 * Usage:
 *   php bootstrap-hr.php                 apply pending/changed files, then verify
 *   php bootstrap-hr.php --check         verify only, never write (doctor)
 *   php bootstrap-hr.php --force         re-apply every file
 *   php bootstrap-hr.php --file=29_x.sql apply one file
 *   php bootstrap-hr.php --new=my_thing  scaffold the next numbered SQL file
 *   php bootstrap-hr.php --capture       write a SQL file for hand-made local changes
 *
 * Exit code 0 = schema complete, 1 = something is still missing.
 */
$args = array_slice($argv ?? [], 1);
$optCheck = in_array('--check', $args, true);
$optForce = in_array('--force', $args, true);
$optFile = null;
$optNew = null;
$optCapture = null;
foreach ($args as $arg) {
    if (str_starts_with($arg, '--file=')) {
        $optFile = basename(substr($arg, 7));
    }
    if (str_starts_with($arg, '--new=')) {
        $optNew = substr($arg, 6);
    }
    if ($arg === '--capture') {
        $optCapture = 'local_changes';
    } elseif (str_starts_with($arg, '--capture=')) {
        $optCapture = substr($arg, 10);
    }
}

function say(string $line): void
{
    echo '[hr360-schema] '.$line."\n";
}

function shout(string $line): void
{
    fwrite(STDERR, '[hr360-schema] '.$line."\n");
}

/** Locate the folder holding database/*.sql (image path first, then repo path). */
function findSqlDir(): string
{
    $candidates = array_values(array_filter([
        getenv('HR360_SQL_DIR') ?: '',
        __DIR__.'/database-sql',
        dirname(__DIR__).'/database',
    ]));
    foreach ($candidates as $dir) {
        if ($dir !== '' && is_dir($dir)) {
            return $dir;
        }
    }
    throw new RuntimeException('SQL folder not found. Looked in: '.implode(', ', $candidates));
}

/** Fill missing env vars from backend/.env so local runs need no setup. */
function loadEnvFile(string $path): void
{
    if (!is_file($path)) {
        return;
    }
    foreach (file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) ?: [] as $line) {
        $line = trim($line);
        if ($line === '' || str_starts_with($line, '#') || !str_contains($line, '=')) {
            continue;
        }
        [$key, $value] = explode('=', $line, 2);
        $key = trim($key);
        $value = trim(trim($value), "\"'");
        if ($key !== '' && getenv($key) === false) {
            putenv($key.'='.$value);
        }
    }
}

loadEnvFile(__DIR__.'/.env');

$host = getenv('DB_HOST') ?: '127.0.0.1';
$port = getenv('DB_PORT') ?: '3306';
$appDb = getenv('DB_DATABASE') ?: 'hr360_demo';
$appUser = getenv('DB_USERNAME') ?: 'root';
$appPass = getenv('DB_PASSWORD') ?: '';
$masterDb = getenv('DB_MASTER_DATABASE') ?: 'hr360_master';
$rootPass = getenv('DB_ROOT_PASSWORD') ?: '';

/** Files that must never run against the tenant DB. */
$skipFiles = ['01_master.sql', '11_reset_employee_passwords.sql'];

// ── --new=name: scaffold the next migration file and stop ────────────────
if ($optNew !== null) {
    $slug = strtolower(preg_replace('/[^A-Za-z0-9]+/', '_', $optNew) ?? '');
    $slug = trim($slug, '_');
    if ($slug === '') {
        shout('--new needs a name, e.g. --new=employee_photos');
        exit(1);
    }
    $path = nextSqlFilePath(findSqlDir(), $slug);
    file_put_contents($path, <<<SQL
-- {$slug}
-- Runs on local (hr360_demo) and production (rewritten to \$DB_DATABASE).
-- Always use CREATE TABLE IF NOT EXISTS, and the guarded block below for columns.
USE hr360_demo;

CREATE TABLE IF NOT EXISTS example_table (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(191) NOT NULL,
  created_at DATETIME NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Add a column only when it is missing:
SET @db := DATABASE();
SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE example_table ADD COLUMN note VARCHAR(255) NULL AFTER name',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='example_table' AND COLUMN_NAME='note');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SQL);
    say('created '.$path);
    say('edit it, then run: php bootstrap-hr.php');
    exit(0);
}

function pdo(string $host, string $port, string $user, string $pass, ?string $db = null): PDO
{
    $dsn = "mysql:host={$host};port={$port};charset=utf8mb4";
    if ($db !== null) {
        $dsn .= ';dbname='.$db;
    }

    return new PDO($dsn, $user, $pass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::MYSQL_ATTR_MULTI_STATEMENTS => true,
        PDO::MYSQL_ATTR_USE_BUFFERED_QUERY => true,
    ]);
}

/** Point every hr360_demo reference at the real target database. */
function rewriteTenantSql(string $sql, string $appDb): string
{
    $safe = str_replace('`', '', $appDb);
    $sql = preg_replace('/CREATE\s+DATABASE\s+IF\s+NOT\s+EXISTS\s+`?hr360_demo`?[^;]*;/i', '', $sql) ?? $sql;
    $sql = preg_replace('/USE\s+`?hr360_demo`?\s*;/i', 'USE `'.$safe.'`;', $sql) ?? $sql;
    $sql = preg_replace('/`hr360_demo`\./i', '`'.$safe.'`.', $sql) ?? $sql;
    $sql = preg_replace('/\bhr360_demo\./i', '`'.$safe.'`.', $sql) ?? $sql;
    $sql = preg_replace('/\bADD\s+COLUMN\s+IF\s+NOT\s+EXISTS\b/i', 'ADD COLUMN', $sql) ?? $sql;

    return $sql;
}

/** Contents of the bracket starting at $openPos, honouring nesting and quotes. */
function extractBalanced(string $sql, int $openPos): ?string
{
    $depth = 0;
    $quote = null;
    $len = strlen($sql);

    for ($i = $openPos; $i < $len; $i++) {
        $ch = $sql[$i];

        if ($quote !== null) {
            if ($ch === '\\') {
                $i++;
            } elseif ($ch === $quote) {
                $quote = null;
            }

            continue;
        }

        if ($ch === "'" || $ch === '"' || $ch === '`') {
            $quote = $ch;
        } elseif ($ch === '(') {
            $depth++;
        } elseif ($ch === ')') {
            if (--$depth === 0) {
                return substr($sql, $openPos + 1, $i - $openPos - 1);
            }
        }
    }

    return null;
}

/**
 * What a SQL file promises to create.
 *
 * `inline` holds columns declared inside CREATE TABLE bodies. They are not
 * verified (an already-existing table will not pick them up), but they tell
 * --capture which columns are already covered by a committed file.
 *
 * @return array{tables: list<string>, columns: list<array{0: string, 1: string}>, inline: array<string, true>}
 */
function parseExpectations(string $sql): array
{
    $clean = preg_replace('/^\s*--.*$/m', '', $sql) ?? $sql;
    $clean = preg_replace('/\/\*.*?\*\//s', '', $clean) ?? $clean;

    $tables = [];
    if (preg_match_all('/CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?`?([A-Za-z0-9_]+)`?/i', $clean, $m)) {
        foreach ($m[1] as $t) {
            if (strtolower($t) !== '_schema_migrations') {
                $tables[strtolower($t)] = $t;
            }
        }
    }

    // Walk ALTER TABLE markers and ADD COLUMN clauses in order, so a single
    // ALTER carrying several ADD COLUMN clauses is fully understood.
    $columns = [];
    $pattern = '/ALTER\s+TABLE\s+`?([A-Za-z0-9_]+)`?|ADD\s+COLUMN\s+(?:IF\s+NOT\s+EXISTS\s+)?`?([A-Za-z0-9_]+)`?/i';
    if (preg_match_all($pattern, $clean, $m, PREG_SET_ORDER)) {
        $current = null;
        foreach ($m as $hit) {
            if (($hit[1] ?? '') !== '') {
                $current = $hit[1];

                continue;
            }
            if ($current !== null && ($hit[2] ?? '') !== '') {
                $columns[strtolower($current).'.'.strtolower($hit[2])] = [$current, $hit[2]];
            }
        }
    }

    $inline = [];
    $createRe = '/CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?`?([A-Za-z0-9_]+)`?\s*\(/i';
    if (preg_match_all($createRe, $clean, $m, PREG_OFFSET_CAPTURE | PREG_SET_ORDER)) {
        foreach ($m as $hit) {
            $table = strtolower($hit[1][0]);
            $body = extractBalanced($clean, $hit[0][1] + strlen($hit[0][0]) - 1);
            if ($body === null) {
                continue;
            }
            foreach (splitAlterClauses($body) as $clause) {
                if (preg_match('/^(PRIMARY|UNIQUE|KEY|INDEX|CONSTRAINT|FOREIGN|CHECK|FULLTEXT|SPATIAL)\b/i', $clause)) {
                    continue;
                }
                if (preg_match('/^`?([A-Za-z0-9_]+)`?/', $clause, $cm)) {
                    $inline[$table.'.'.strtolower($cm[1])] = true;
                }
            }
        }
    }

    return [
        'tables' => array_values($tables),
        'columns' => array_values($columns),
        'inline' => $inline,
    ];
}

/** Next free `NN_slug.sql` path in the SQL folder. */
function nextSqlFilePath(string $dir, string $slug): string
{
    $next = 1;
    foreach (glob($dir.DIRECTORY_SEPARATOR.'*.sql') ?: [] as $existing) {
        if (preg_match('/^(\d+)_/', basename($existing), $m)) {
            $next = max($next, ((int) $m[1]) + 1);
        }
    }

    return $dir.DIRECTORY_SEPARATOR.sprintf('%02d_%s.sql', $next, $slug);
}

/** Rebuild a column definition from information_schema. */
function columnDefinitionSql(array $row): string
{
    $sql = '`'.$row['COLUMN_NAME'].'` '.$row['COLUMN_TYPE'];
    $sql .= ($row['IS_NULLABLE'] === 'NO') ? ' NOT NULL' : ' NULL';

    $default = $row['COLUMN_DEFAULT'];
    if ($default !== null) {
        $raw = trim((string) $default);
        // MariaDB already returns string defaults wrapped in quotes; MySQL does not.
        $literal = preg_match("/^'.*'$/s", $raw) === 1
            || preg_match('/^(NULL|CURRENT_TIMESTAMP(\(\d*\))?|current_timestamp(\(\d*\))?|-?\d+(\.\d+)?)$/i', $raw) === 1
            || stripos((string) ($row['EXTRA'] ?? ''), 'DEFAULT_GENERATED') !== false;
        $sql .= ' DEFAULT '.($literal ? $raw : "'".str_replace("'", "''", $raw)."'");
    } elseif ($row['IS_NULLABLE'] !== 'NO') {
        $sql .= ' DEFAULT NULL';
    }

    if (stripos((string) ($row['EXTRA'] ?? ''), 'on update current_timestamp') !== false) {
        $sql .= ' ON UPDATE CURRENT_TIMESTAMP';
    }
    if (($row['COLUMN_COMMENT'] ?? '') !== '') {
        $sql .= " COMMENT '".str_replace("'", "''", (string) $row['COLUMN_COMMENT'])."'";
    }

    return $sql;
}

/** Idempotent, MySQL-safe ADD COLUMN block. */
function captureColumnBlock(string $table, string $column, string $definition, ?string $after): string
{
    $alter = 'ALTER TABLE `'.$table.'` ADD COLUMN '.$definition;
    $alter .= $after !== null ? ' AFTER `'.$after.'`' : ' FIRST';
    $escaped = str_replace("'", "''", $alter);

    return <<<SQL
SET @sql := (SELECT IF(COUNT(*)=0,
  '{$escaped}',
  'SELECT 1') FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='{$table}' AND COLUMN_NAME='{$column}');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SQL;
}

function isIgnorableSqlError(Throwable $e): bool
{
    return (bool) preg_match(
        '/Duplicate column name|Duplicate key name|already exists|1060|1061|1050|Duplicate entry/i',
        $e->getMessage()
    );
}

/**
 * Split an ALTER body on top-level commas, ignoring commas inside brackets or
 * quotes so that types such as DECIMAL(12,2) survive intact.
 *
 * @return list<string>
 */
function splitAlterClauses(string $body): array
{
    $out = [];
    $buf = '';
    $depth = 0;
    $quote = null;
    $len = strlen($body);

    for ($i = 0; $i < $len; $i++) {
        $ch = $body[$i];

        if ($quote !== null) {
            $buf .= $ch;
            if ($ch === '\\' && $i + 1 < $len) {
                $buf .= $body[++$i];
            } elseif ($ch === $quote) {
                $quote = null;
            }

            continue;
        }

        if ($ch === "'" || $ch === '"' || $ch === '`') {
            $quote = $ch;
        } elseif ($ch === '(') {
            $depth++;
        } elseif ($ch === ')') {
            $depth--;
        } elseif ($ch === ',' && $depth === 0) {
            $out[] = trim($buf);
            $buf = '';

            continue;
        }

        $buf .= $ch;
    }

    if (trim($buf) !== '') {
        $out[] = trim($buf);
    }

    return array_values(array_filter($out, fn ($c) => $c !== ''));
}

/**
 * One ALTER per clause. A single bad clause (for example an AFTER pointing at a
 * column this database never got) then cannot block the other columns.
 *
 * @return list<string>
 */
function expandAlter(string $sql): array
{
    if (!preg_match('/^\s*ALTER\s+TABLE\s+(`?[A-Za-z0-9_]+`?)\s+(.*)$/is', $sql, $m)) {
        return [$sql];
    }
    $clauses = splitAlterClauses($m[2]);
    if (count($clauses) < 2) {
        return [$sql];
    }

    return array_map(fn ($clause) => 'ALTER TABLE '.$m[1].' '.$clause, $clauses);
}

/** Drop a trailing `AFTER col` so a column can still be added at the end. */
function stripAfterClause(string $sql): ?string
{
    $stripped = preg_replace('/\s+AFTER\s+`?[A-Za-z0-9_]+`?\s*$/i', '', $sql);

    return ($stripped !== null && $stripped !== $sql) ? $stripped : null;
}

/**
 * Run one chunk. Guarded `PREPARE … EXECUTE …` blocks return result sets that
 * must be drained, otherwise the connection goes out of sync; plain DDL/DML
 * goes through exec() so real errors surface.
 */
function runChunk(PDO $conn, string $sql): void
{
    $multi = substr_count(rtrim($sql, "; \t\r\n"), ';') > 0;
    if (!$multi && !preg_match('/^\s*(SELECT|SHOW|DESCRIBE|EXECUTE|PREPARE)\b/i', $sql)) {
        $conn->exec($sql);

        return;
    }

    $stmt = $conn->query($sql);
    if ($stmt === false) {
        return;
    }
    try {
        while ($stmt->nextRowset()) {
            // Drain remaining result sets.
        }
    } catch (PDOException $e) {
        // Thrown once the driver runs out of result sets.
    }
    $stmt->closeCursor();
}

/**
 * Apply one SQL file statement by statement. Duplicate-object errors are
 * expected on re-runs and skipped; everything the file promised is verified
 * by the caller afterwards.
 */
function applySqlFile(PDO $conn, string $path, string $appDb): void
{
    $raw = file_get_contents($path);
    if ($raw === false) {
        throw new RuntimeException('Cannot read '.$path);
    }
    $sql = trim(rewriteTenantSql($raw, $appDb));
    if ($sql === '') {
        return;
    }

    $sql = preg_replace('/\/\*.*?\*\//s', '', $sql) ?? $sql;
    $sql = preg_replace('/^\s*--.*$/m', '', $sql) ?? $sql;

    foreach (preg_split('/;\s*[\r\n]+/', $sql) ?: [] as $part) {
        $stmt = trim(rtrim(trim($part), ';'));
        if ($stmt === '' || strcasecmp($stmt, 'SELECT 1') === 0) {
            continue;
        }

        foreach (expandAlter($stmt) as $one) {
            try {
                runChunk($conn, $one);
            } catch (PDOException $e) {
                if (isIgnorableSqlError($e)) {
                    continue;
                }

                // `AFTER x` where x never existed here: add the column at the end.
                $retry = stripAfterClause($one);
                if ($retry !== null && stripos($e->getMessage(), 'Unknown column') !== false) {
                    try {
                        runChunk($conn, $retry);

                        continue;
                    } catch (PDOException $inner) {
                        if (isIgnorableSqlError($inner)) {
                            continue;
                        }
                        throw $inner;
                    }
                }

                throw $e;
            }
        }
    }
}

/** A failed multi-statement batch can leave the link dirty; hand back a clean one. */
function pdoReconnect(PDO $conn): PDO
{
    global $host, $port, $appUser, $appPass, $appDb;

    try {
        $conn->query('SELECT 1')?->closeCursor();

        return $conn;
    } catch (Throwable $e) {
        return pdo($host, $port, $appUser, $appPass, $appDb);
    }
}

/** @return array<string, true> lowercase table names present in the DB */
function loadTables(PDO $conn): array
{
    $out = [];
    $stmt = $conn->query('SELECT LOWER(TABLE_NAME) AS t FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE()');
    foreach ($stmt?->fetchAll(PDO::FETCH_COLUMN) ?: [] as $name) {
        $out[(string) $name] = true;
    }

    return $out;
}

/** @return array<string, true> lowercase "table.column" keys present in the DB */
function loadColumns(PDO $conn): array
{
    $out = [];
    $stmt = $conn->query('SELECT LOWER(CONCAT(TABLE_NAME, ".", COLUMN_NAME)) AS c FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE()');
    foreach ($stmt?->fetchAll(PDO::FETCH_COLUMN) ?: [] as $name) {
        $out[(string) $name] = true;
    }

    return $out;
}

try {
    $sqlDir = findSqlDir();

    // ── Databases + privileges (only possible when the root password is known)
    if ($rootPass !== '' && !$optCheck) {
        $root = pdo($host, $port, 'root', $rootPass);
        foreach ([$masterDb, $appDb] as $db) {
            $root->exec('CREATE DATABASE IF NOT EXISTS `'.str_replace('`', '', $db).'` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci');
        }
        $safeUser = str_replace(['`', "'"], '', $appUser);
        foreach ([$masterDb, $appDb] as $db) {
            $root->exec("GRANT ALL PRIVILEGES ON `".str_replace('`', '', $db)."`.* TO '{$safeUser}'@'%'");
        }
        $root->exec('FLUSH PRIVILEGES');
        say('databases ready: '.$masterDb.', '.$appDb);
    }

    // ── Master DB: tenant registry ──────────────────────────────────────
    if (!$optCheck) {
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

        $upsert = $master->prepare(<<<'SQL'
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
        $upsert->execute([
            'host' => $host,
            'db' => $appDb,
            'user' => $appUser,
            'pass' => $appPass,
        ]);
        say('tenant "demo" → '.$appDb.'@'.$host);
    }

    // ── Tenant DB ───────────────────────────────────────────────────────
    $tenant = pdo($host, $port, $appUser, $appPass, $appDb);

    if (!$optCheck) {
        $tenant->exec(<<<'SQL'
CREATE TABLE IF NOT EXISTS `_schema_migrations` (
  `filename` VARCHAR(191) NOT NULL,
  `checksum` CHAR(40) NULL,
  `applied_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`filename`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
SQL);
        // Older installs predate the checksum column.
        $hasChecksum = (int) $tenant->query(
            'SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = "_schema_migrations" AND COLUMN_NAME = "checksum"'
        )->fetchColumn() > 0;
        if (!$hasChecksum) {
            $tenant->exec('ALTER TABLE `_schema_migrations` ADD COLUMN `checksum` CHAR(40) NULL AFTER `filename`');
        }
    }

    // ── Collect every file and what it promises ─────────────────────────
    $files = glob($sqlDir.DIRECTORY_SEPARATOR.'*.sql') ?: [];
    natcasesort($files);
    $files = array_values($files);

    /** @var array<string, array{path: string, checksum: string, tables: list<string>, columns: list<array{0: string, 1: string}>}> */
    $plan = [];
    foreach ($files as $path) {
        $name = basename($path);
        if (in_array($name, $skipFiles, true)) {
            continue;
        }
        if ($optFile !== null && $name !== $optFile) {
            continue;
        }
        $raw = (string) file_get_contents($path);
        $plan[$name] = parseExpectations($raw) + [
            'path' => $path,
            'checksum' => sha1($raw),
        ];
    }

    if ($plan === []) {
        throw new RuntimeException($optFile !== null ? 'No such SQL file: '.$optFile : 'No SQL files found in '.$sqlDir);
    }

    $tables = loadTables($tenant);
    $columns = loadColumns($tenant);

    /** Anything this file promised that the DB does not have. */
    $unmet = function (array $spec) use (&$tables, &$columns): array {
        $missing = [];
        foreach ($spec['tables'] as $t) {
            if (!isset($tables[strtolower($t)])) {
                $missing[] = $t;
            }
        }
        foreach ($spec['columns'] as [$t, $c]) {
            if (!isset($tables[strtolower($t)])) {
                continue; // reported as a missing table instead
            }
            if (!isset($columns[strtolower($t).'.'.strtolower($c)])) {
                $missing[] = $t.'.'.$c;
            }
        }

        return $missing;
    };

    // ── --capture: turn hand-made local changes into a committable file ──
    if ($optCapture !== null) {
        if ($optFile !== null) {
            throw new RuntimeException('--capture cannot be combined with --file');
        }

        $promisedTables = [];
        $promisedColumns = [];
        foreach ($plan as $spec) {
            foreach ($spec['tables'] as $t) {
                $promisedTables[strtolower($t)] = true;
            }
            foreach ($spec['columns'] as [$t, $c]) {
                $promisedColumns[strtolower($t).'.'.strtolower($c)] = true;
            }
            foreach (array_keys($spec['inline']) as $key) {
                $promisedColumns[$key] = true;
            }
        }

        $extraTables = [];
        foreach (array_keys($tables) as $table) {
            if ($table === '_schema_migrations' || isset($promisedTables[$table])) {
                continue;
            }
            $extraTables[] = $table;
        }

        // Columns that exist here but no SQL file creates them.
        $extraColumns = [];
        $rows = $tenant->query(
            'SELECT TABLE_NAME, COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, COLUMN_DEFAULT, EXTRA, COLUMN_COMMENT, ORDINAL_POSITION '
            .'FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() ORDER BY TABLE_NAME, ORDINAL_POSITION'
        )->fetchAll(PDO::FETCH_ASSOC) ?: [];

        $byTable = [];
        foreach ($rows as $row) {
            $byTable[(string) $row['TABLE_NAME']][] = $row;
        }

        foreach ($byTable as $table => $cols) {
            $lowerTable = strtolower($table);
            if ($lowerTable === '_schema_migrations' || in_array($lowerTable, $extraTables, true)) {
                continue; // whole table is dumped separately
            }
            if (!isset($promisedTables[$lowerTable])) {
                continue;
            }
            foreach ($cols as $index => $row) {
                $key = $lowerTable.'.'.strtolower((string) $row['COLUMN_NAME']);
                if (isset($promisedColumns[$key])) {
                    continue;
                }
                $extraColumns[] = [
                    'table' => $table,
                    'column' => (string) $row['COLUMN_NAME'],
                    'definition' => columnDefinitionSql($row),
                    'after' => $index > 0 ? (string) $cols[$index - 1]['COLUMN_NAME'] : null,
                ];
            }
        }

        if ($extraTables === [] && $extraColumns === []) {
            say('nothing to capture — every table and column already comes from database/*.sql');
            exit(0);
        }

        $slug = strtolower(preg_replace('/[^A-Za-z0-9]+/', '_', $optCapture) ?? 'local_changes');
        $slug = trim($slug, '_') ?: 'local_changes';
        $path = nextSqlFilePath($sqlDir, $slug);

        $out = "-- Captured from {$appDb} on ".date('Y-m-d H:i')."\n";
        $out .= "-- Local changes that no other SQL file creates. Safe to re-run.\n";
        $out .= "USE hr360_demo;\n\nSET @db := DATABASE();\n\n";

        foreach ($extraTables as $table) {
            $create = (string) $tenant->query('SHOW CREATE TABLE `'.$table.'`')->fetch(PDO::FETCH_ASSOC)['Create Table'];
            $create = preg_replace('/^CREATE TABLE/i', 'CREATE TABLE IF NOT EXISTS', $create) ?? $create;
            $create = preg_replace('/\s+AUTO_INCREMENT=\d+/i', '', $create) ?? $create;
            $out .= $create.";\n\n";
        }

        foreach ($extraColumns as $col) {
            $out .= captureColumnBlock($col['table'], $col['column'], $col['definition'], $col['after'])."\n";
        }

        file_put_contents($path, $out);
        say('captured '.count($extraTables).' table(s) and '.count($extraColumns).' column(s)');
        say('wrote '.$path);
        say('next: php bootstrap-hr.php --check   then commit the file and deploy');
        exit(0);
    }

    // ── Check-only mode: report and stop ────────────────────────────────
    if ($optCheck) {
        $problems = [];
        foreach ($plan as $name => $spec) {
            $missing = $unmet($spec);
            if ($missing !== []) {
                $problems[$name] = $missing;
            }
        }
        say('database: '.$appDb.'@'.$host.'  ('.count($tables).' tables)');
        if ($problems === []) {
            say('OK — schema is complete, nothing missing.');
            exit(0);
        }
        shout('INCOMPLETE — '.count($problems).' file(s) have missing objects:');
        foreach ($problems as $name => $missing) {
            shout('  '.$name.' → '.implode(', ', $missing));
        }
        shout('Fix with: php bootstrap-hr.php');
        exit(1);
    }

    // ── Recover a login-only stub DB (safe: only when there is no data) ──
    if (!isset($tables['hr_org_division']) && isset($tables['employee'])) {
        $employeeRows = (int) $tenant->query('SELECT COUNT(*) FROM `employee`')->fetchColumn();
        if ($employeeRows <= 1) {
            say('incomplete stub schema detected — rebuilding core tables');
            $tenant->exec('SET FOREIGN_KEY_CHECKS=0');
            foreach (['employee', 'designation', 'company', 'department', 'station', 'project', 'leave', 'leave_type', 'leave_approval'] as $t) {
                $tenant->exec('DROP TABLE IF EXISTS `'.$t.'`');
            }
            $tenant->exec('SET FOREIGN_KEY_CHECKS=1');
            $tenant->exec('DELETE FROM `_schema_migrations`');
            $tables = loadTables($tenant);
            $columns = loadColumns($tenant);
        } else {
            say('warning: hr_org_division missing but employee has data — leaving tables untouched');
        }
    }

    $appliedRows = [];
    foreach ($tenant->query('SELECT filename, checksum FROM `_schema_migrations`')->fetchAll(PDO::FETCH_ASSOC) ?: [] as $row) {
        $appliedRows[(string) $row['filename']] = (string) ($row['checksum'] ?? '');
    }

    $mark = $tenant->prepare(
        'INSERT INTO `_schema_migrations` (filename, checksum) VALUES (?, ?) '
        .'ON DUPLICATE KEY UPDATE checksum = VALUES(checksum), applied_at = CURRENT_TIMESTAMP'
    );

    // An existing database (yours, or a production one built before checksums were
    // tracked) must not have seed inserts replayed. Files whose objects are all
    // present are recorded as applied instead of re-run.
    $existingDatabase = count(array_diff_key($tables, ['_schema_migrations' => true])) > 0;

    $appliedCount = 0;
    $adoptedCount = 0;
    $skippedCount = 0;
    $failures = [];

    foreach ($plan as $name => $spec) {
        $known = array_key_exists($name, $appliedRows);
        $changed = $known && $appliedRows[$name] !== $spec['checksum'];
        $missing = $unmet($spec);

        if (!$known && !$optForce && $existingDatabase && $missing === []
            && ($spec['tables'] !== [] || $spec['columns'] !== [])) {
            $mark->execute([$name, $spec['checksum']]);
            $adoptedCount++;

            continue;
        }

        $reason = null;
        if ($optForce) {
            $reason = 'forced';
        } elseif (!$known) {
            $reason = 'new';
        } elseif ($changed) {
            $reason = 'file changed';
        } elseif ($missing !== []) {
            $reason = 'missing: '.implode(', ', array_slice($missing, 0, 4)).(count($missing) > 4 ? ', …' : '');
        }

        if ($reason === null) {
            $skippedCount++;

            continue;
        }

        say('applying '.$name.' ('.$reason.')');
        try {
            applySqlFile($tenant, $spec['path'], $appDb);
        } catch (Throwable $e) {
            $failures[$name] = 'error: '.$e->getMessage();
            $tenant = pdoReconnect($tenant);

            continue;
        }
        $mark->execute([$name, $spec['checksum']]);
        $appliedCount++;

        $tables = loadTables($tenant);
        $columns = loadColumns($tenant);
        $stillMissing = $unmet($spec);
        if ($stillMissing !== []) {
            $failures[$name] = 'still missing: '.implode(', ', $stillMissing);
        }
    }

    say('applied '.$appliedCount.' file(s)'
        .($adoptedCount > 0 ? ', adopted '.$adoptedCount.' already-present file(s)' : '')
        .', up to date '.$skippedCount);

    // ── Seed the admin login once the core tables exist ─────────────────
    if (isset($tables['employee']) && (getenv('HR360_SKIP_SEED') ?: '0') !== '1') {
        if (!isset($columns['employee.surname'])) {
            $tenant->exec('ALTER TABLE `employee` ADD COLUMN `surname` VARCHAR(191) NULL AFTER `name`');
        }
        $hash = password_hash('admin', PASSWORD_BCRYPT);
        $find = $tenant->prepare('SELECT employee_id FROM employee WHERE user_name = ? LIMIT 1');
        $find->execute(['admin']);
        $adminId = $find->fetchColumn();
        if ($adminId) {
            $upd = $tenant->prepare('UPDATE employee SET password = ?, status = 2, is_first_login = 0 WHERE employee_id = ?');
            $upd->execute([$hash, $adminId]);
        } else {
            $ins = $tenant->prepare('INSERT INTO employee (name, surname, user_name, email, password, status, designation, employee_code, is_first_login) VALUES (?,?,?,?,?,2,1,?,0)');
            $ins->execute(['Demo', 'Admin', 'admin', 'admin@demo.local', $hash, 'EMP-0001']);
        }
        say('login ready: organization demo / admin / admin');
    }

    // ── Final verdict ───────────────────────────────────────────────────
    $tables = loadTables($tenant);
    $columns = loadColumns($tenant);
    $problems = [];
    foreach ($plan as $name => $spec) {
        $detail = [];
        if (isset($failures[$name])) {
            $detail[] = $failures[$name];
        }
        $missing = $unmet($spec);
        if ($missing !== []) {
            $detail[] = 'missing: '.implode(', ', $missing);
        }
        if ($detail !== []) {
            $problems[$name] = implode(' | ', $detail);
        }
    }

    if ($problems === []) {
        say('OK — schema complete ('.count($tables).' tables in '.$appDb.')');
        exit(0);
    }

    shout('');
    shout('=========== SCHEMA INCOMPLETE ===========');
    foreach ($problems as $name => $detail) {
        shout($name.' → '.$detail);
    }
    shout('=========================================');
    shout('Retry with: php bootstrap-hr.php --force');
    exit(1);
} catch (Throwable $e) {
    shout('FAILED: '.$e->getMessage());
    exit(1);
}
