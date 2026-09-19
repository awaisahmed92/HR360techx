<?php

namespace App\Services;

use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\DB;
use stdClass;

class TenantManager
{
    public static function findBySubdomain(string $subdomain): ?object
    {
        return DB::connection('master')
            ->table('tenants')
            ->where('subdomain', $subdomain)
            ->where('status', 'active')
            ->first();
    }

    public static function connect(object $tenant): void
    {
        Config::set('database.connections.tenant', [
            'driver' => 'mysql',
            'host' => $tenant->db_host ?: '127.0.0.1',
            'port' => 3306,
            'database' => $tenant->db_name,
            'username' => $tenant->db_user ?: 'root',
            'password' => $tenant->db_password ?? '',
            'charset' => 'utf8mb4',
            'collation' => 'utf8mb4_unicode_ci',
            'prefix' => '',
            'strict' => false,
        ]);

        DB::purge('tenant');
        DB::reconnect('tenant');
        Config::set('database.default', 'tenant');
    }

    public static function issueToken(array $claims): string
    {
        $claims['exp'] = time() + 60 * 60 * 12;
        $payload = rtrim(strtr(base64_encode(json_encode($claims)), '+/', '-_'), '=');
        $sig = hash_hmac('sha256', $payload, config('app.hr360_token_secret'));

        return $payload.'.'.$sig;
    }

    public static function parseToken(?string $bearer): ?array
    {
        if (!$bearer || !preg_match('/Bearer\s+(\S+)/i', $bearer, $m)) {
            return null;
        }
        $parts = explode('.', $m[1], 2);
        if (count($parts) !== 2) {
            return null;
        }
        [$payload, $sig] = $parts;
        $expected = hash_hmac('sha256', $payload, config('app.hr360_token_secret'));
        if (!hash_equals($expected, $sig)) {
            return null;
        }
        $claims = json_decode(base64_decode(strtr($payload, '-_', '+/')), true);
        if (!is_array($claims) || empty($claims['subdomain']) || ($claims['exp'] ?? 0) < time()) {
            return null;
        }

        return $claims;
    }

    public static function normalizePermissions(array $rolls, bool $all = false): array
    {
        if ($all) {
            return ['all' => true, 'modules' => new stdClass];
        }
        $out = [];
        foreach ($rolls as $module => $data) {
            if (!is_array($data)) {
                continue;
            }
            $entry = [
                'enabled' => !empty($data['roll']) && (string) $data['roll'] === '1',
                'screens' => [],
            ];
            foreach ($data as $screen => $flags) {
                if ($screen === 'roll' || !is_array($flags)) {
                    continue;
                }
                $entry['screens'][$screen] = [
                    'view' => !empty($flags[0]) && (string) $flags[0] === '1',
                    'add' => !empty($flags[1]) && (string) $flags[1] === '1',
                    'edit' => !empty($flags[2]) && (string) $flags[2] === '1',
                    'delete' => !empty($flags[3]) && (string) $flags[3] === '1',
                ];
            }
            $out[$module] = $entry;
        }

        return ['all' => false, 'modules' => $out];
    }
}
