<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use PDO;
use RuntimeException;
use Symfony\Component\Process\Process;

/**
 * Creates a brand-new organization: its own database with the full HR schema,
 * a single admin employee, and a row in the master tenant registry.
 */
class TenantProvisioner
{
    /** Codes that would clash with system databases or the demo org. */
    public const RESERVED_CODES = [
        'demo', 'master', 'admin', 'administrator', 'api', 'www', 'app', 'root',
        'hr360', 'test', 'mysql', 'sys', 'public', 'information_schema',
        'performance_schema', 'null', 'undefined', 'signup', 'login',
    ];

    /**
     * Reduce user input to a safe organization code.
     * Letters, digits and underscores only, lowercase.
     */
    public static function normalizeCode(string $raw): string
    {
        $code = strtolower(trim($raw));
        $code = preg_replace('/[^a-z0-9_]+/', '', $code) ?? '';

        return substr($code, 0, 40);
    }

    public static function databaseNameFor(string $code): string
    {
        return 'hr360_'.$code;
    }

    /** Is this code free to use? */
    public static function codeTaken(string $code): bool
    {
        return DB::connection('master')
            ->table('tenants')
            ->where('subdomain', $code)
            ->orWhere('company_code', $code)
            ->exists();
    }

    /**
     * @param array{
     *   company_name: string, company_code: string, contact_name: string,
     *   designation: string, industry: string, country: string,
     *   email: string, phone: ?string, password: string
     * } $input
     *
     * @return array{tenant_id: int, db_name: string, user_name: string, employee_id: int}
     */
    public function provision(array $input): array
    {
        $code = $input['company_code'];
        $dbName = self::databaseNameFor($code);
        $created = false;
        $tenantId = null;

        try {
            $this->createDatabase($dbName);
            $created = true;

            $this->installSchema($dbName);

            $employeeId = $this->seedAdmin($dbName, $input);
            $tenantId = $this->registerTenant($dbName, $input, $employeeId);

            return [
                'tenant_id' => $tenantId,
                'db_name' => $dbName,
                'user_name' => $this->adminUserName($input['contact_name']),
                'employee_id' => $employeeId,
            ];
        } catch (\Throwable $e) {
            // Never leave a half-built organization behind.
            if ($tenantId !== null) {
                DB::connection('master')->table('tenant_admins')->where('tenant_id', $tenantId)->delete();
                DB::connection('master')->table('tenants')->where('id', $tenantId)->delete();
            }
            if ($created) {
                try {
                    $this->serverConnection()->statement('DROP DATABASE IF EXISTS `'.$dbName.'`');
                } catch (\Throwable $ignored) {
                    // Reported through the original exception below.
                }
            }
            throw $e;
        }
    }

    /** A connection with no database selected, using root when its password is known. */
    protected function serverConnection(): \Illuminate\Database\Connection
    {
        $rootPass = (string) env('DB_ROOT_PASSWORD', '');
        $name = 'tenant_provision_server';

        config([
            'database.connections.'.$name => [
                'driver' => 'mysql',
                'host' => env('DB_HOST', '127.0.0.1'),
                'port' => env('DB_PORT', '3306'),
                'database' => null,
                'username' => $rootPass !== '' ? 'root' : env('DB_USERNAME', 'root'),
                'password' => $rootPass !== '' ? $rootPass : env('DB_PASSWORD', ''),
                'charset' => 'utf8mb4',
                'collation' => 'utf8mb4_unicode_ci',
                'prefix' => '',
                'strict' => false,
            ],
        ]);
        DB::purge($name);

        return DB::connection($name);
    }

    protected function createDatabase(string $dbName): void
    {
        $server = $this->serverConnection();
        $exists = $server->selectOne(
            'SELECT SCHEMA_NAME FROM information_schema.SCHEMATA WHERE SCHEMA_NAME = ?',
            [$dbName]
        );
        if ($exists !== null) {
            throw new RuntimeException('A database for this company code already exists.');
        }

        $server->statement('CREATE DATABASE `'.$dbName.'` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci');

        // The API user must be able to reach the new database.
        $rootPass = (string) env('DB_ROOT_PASSWORD', '');
        $appUser = (string) env('DB_USERNAME', 'root');
        if ($rootPass !== '' && $appUser !== 'root') {
            $safeUser = str_replace(['`', "'"], '', $appUser);
            $server->statement("GRANT ALL PRIVILEGES ON `{$dbName}`.* TO '{$safeUser}'@'%'");
            $server->statement('FLUSH PRIVILEGES');
        }
    }

    /** Build the full HR schema in the new database and leave it empty. */
    protected function installSchema(string $dbName): void
    {
        $script = base_path('bootstrap-hr.php');
        if (!is_file($script)) {
            throw new RuntimeException('Schema installer not found at '.$script);
        }

        $process = new Process(
            [$this->phpBinary(), $script, '--provision='.$dbName],
            base_path(),
            [
                'DB_HOST' => (string) env('DB_HOST', '127.0.0.1'),
                'DB_PORT' => (string) env('DB_PORT', '3306'),
                'DB_USERNAME' => (string) env('DB_USERNAME', 'root'),
                'DB_PASSWORD' => (string) env('DB_PASSWORD', ''),
                'DB_ROOT_PASSWORD' => (string) env('DB_ROOT_PASSWORD', ''),
                'HR360_SQL_DIR' => (string) env('HR360_SQL_DIR', ''),
            ],
            null,
            300
        );
        $process->run();

        if (!$process->isSuccessful()) {
            throw new RuntimeException(
                'Schema install failed: '.trim($process->getErrorOutput()."\n".$process->getOutput())
            );
        }
    }

    /**
     * Path to the PHP CLI. Under mod_php, PHP_BINARY is the web server binary,
     * so it is only trusted when running from the command line.
     */
    protected function phpBinary(): string
    {
        $windows = DIRECTORY_SEPARATOR === '\\';
        $exe = $windows ? 'php.exe' : 'php';

        $candidates = [(string) env('HR360_PHP_BINARY', '')];
        if (PHP_SAPI === 'cli') {
            $candidates[] = PHP_BINARY;
        }
        $candidates[] = PHP_BINDIR.DIRECTORY_SEPARATOR.$exe;
        $ini = php_ini_loaded_file();
        if ($ini !== false) {
            $candidates[] = dirname($ini).DIRECTORY_SEPARATOR.$exe;
        }

        foreach ($candidates as $candidate) {
            if ($candidate !== '' && is_file($candidate)) {
                return $candidate;
            }
        }

        return $windows ? 'php.exe' : 'php';
    }

    /**
     * Insert the organization's only rows: the company, the admin's job title,
     * and the admin employee with every right enabled.
     */
    protected function seedAdmin(string $dbName, array $input): int
    {
        $pdo = $this->tenantPdo($dbName);

        $pdo->prepare('INSERT INTO `company` (`name`, `hr_company_name`, `code`, `email`) VALUES (?,?,?,?)')
            ->execute([
                $input['company_name'],
                $input['company_name'],
                $input['company_code'],
                $input['email'],
            ]);

        $designation = $input['designation'] !== '' ? $input['designation'] : 'Administrator';
        $rights = serialize($this->allRights());
        $pdo->prepare('INSERT INTO `designation` (`name`, `rolls`) VALUES (?, ?)')
            ->execute([$designation, $rights]);
        $designationId = (int) $pdo->lastInsertId();

        $userName = $this->adminUserName($input['contact_name']);
        $columns = [
            'name' => $input['contact_name'],
            'user_name' => $userName,
            'email' => $input['email'],
            'password' => Hash::make($input['password']),
            'status' => 2, // 2 = admin / all access
            'designation' => $designationId,
            'employee_code' => 'EMP-0001',
            'is_first_login' => 0,
            'rolls' => $rights,
        ];

        // Optional columns depend on which SQL files a deployment has applied.
        $present = [];
        $stmt = $pdo->prepare(
            'SELECT LOWER(COLUMN_NAME) FROM information_schema.COLUMNS '
            .'WHERE TABLE_SCHEMA = ? AND TABLE_NAME = "employee"'
        );
        $stmt->execute([$dbName]);
        foreach ($stmt->fetchAll(PDO::FETCH_COLUMN) ?: [] as $name) {
            $present[(string) $name] = true;
        }
        if (isset($present['contact_number']) && !empty($input['phone'])) {
            $columns['contact_number'] = $input['phone'];
        }
        $columns = array_filter(
            $columns,
            fn ($key) => isset($present[strtolower($key)]),
            ARRAY_FILTER_USE_KEY
        );

        $names = array_keys($columns);
        $sql = 'INSERT INTO `employee` (`'.implode('`, `', $names).'`) VALUES ('
            .implode(', ', array_fill(0, count($names), '?')).')';
        $pdo->prepare($sql)->execute(array_values($columns));

        return (int) $pdo->lastInsertId();
    }

    protected function registerTenant(string $dbName, array $input, int $employeeId): int
    {
        $master = DB::connection('master');
        $tenantId = (int) $master->table('tenants')->insertGetId([
            'name' => $input['company_name'],
            'subdomain' => $input['company_code'],
            'company_code' => $input['company_code'],
            'db_host' => (string) env('DB_HOST', '127.0.0.1'),
            'db_name' => $dbName,
            'db_user' => (string) env('DB_USERNAME', 'root'),
            'db_password' => (string) env('DB_PASSWORD', ''),
            'status' => 'active',
            'hr_app' => 1,
            'industry' => $input['industry'],
            'country' => $input['country'],
            'contact_name' => $input['contact_name'],
            'contact_designation' => $input['designation'],
            'contact_email' => $input['email'],
            'contact_phone' => $input['phone'] ?? null,
            'source' => 'signup',
        ]);

        $master->table('tenant_admins')->insert([
            'tenant_id' => $tenantId,
            'name' => $input['contact_name'],
            'designation' => $input['designation'],
            'email' => $input['email'],
            'user_name' => $this->adminUserName($input['contact_name']),
            'employee_id' => $employeeId,
        ]);

        return $tenantId;
    }

    protected function tenantPdo(string $dbName): PDO
    {
        $dsn = 'mysql:host='.env('DB_HOST', '127.0.0.1')
            .';port='.env('DB_PORT', '3306')
            .';dbname='.$dbName
            .';charset=utf8mb4';

        return new PDO($dsn, (string) env('DB_USERNAME', 'root'), (string) env('DB_PASSWORD', ''), [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        ]);
    }

    /** Login UserName. This is the Name entered on the sign-up form. */
    public function adminUserName(string $name): string
    {
        $name = trim(preg_replace('/\s+/', ' ', $name) ?? '');

        return $name !== '' ? substr($name, 0, 90) : 'admin';
    }

    /**
     * Every module and screen switched on. Mirrors the catalog in
     * EmployeeController::roleCatalog(); employee.status = 2 is the real gate,
     * this makes the Roles screen show everything ticked.
     *
     * @return array<string, array<string, mixed>>
     */
    protected function allRights(): array
    {
        $catalog = [
            'general' => ['profile', 'settings'],
            'dashboard' => ['my_dashboard', 'hr_dashboard'],
            'organization' => ['companies', 'departments', 'designations', 'stations'],
            'employees' => ['employees', 'employee_roles', 'onboarding', 'contracts'],
            'timesheet' => ['attendance', 'leave', 'timesheet'],
            'payroll' => ['payroll_setup', 'payroll_define', 'payroll_process'],
            'reports' => ['reports'],
            'other' => ['travel', 'approvals'],
            'calendar' => ['calendar'],
        ];

        $rolls = [];
        foreach ($catalog as $module => $screens) {
            $entry = ['roll' => '1'];
            foreach ($screens as $screen) {
                $entry[$screen] = ['1', '1', '1', '1'];
            }
            $rolls[$module] = $entry;
        }

        return $rolls;
    }
}
