<?php

function hr360_config(): array
{
    static $cfg;
    if ($cfg === null) {
        $cfg = require __DIR__ . '/config.php';
    }
    return $cfg;
}

function hr360_cors(): void
{
    $origin = hr360_config()['cors_origin'] ?? '*';
    header('Access-Control-Allow-Origin: ' . $origin);
    header('Access-Control-Allow-Headers: Authorization, Content-Type, Accept');
    header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
    header('Content-Type: application/json; charset=utf-8');
}

function hr360_json(array $data, int $code = 200): void
{
    hr360_cors();
    http_response_code($code);
    echo json_encode($data, JSON_UNESCAPED_UNICODE);
    exit;
}

function hr360_ok(array $data = [], int $code = 200): void
{
    hr360_json(array_merge(['success' => true], $data), $code);
}

function hr360_error(string $message, int $code = 400): void
{
    hr360_json(['success' => false, 'message' => $message], $code);
}

function hr360_body(): array
{
    $raw = file_get_contents('php://input');
    $json = json_decode($raw ?: '', true);
    if (is_array($json)) {
        return $json;
    }
    return $_POST ?: [];
}

function hr360_pdo_master(): PDO
{
    $m = hr360_config()['master'];
    $dsn = sprintf(
        'mysql:host=%s;port=%d;dbname=%s;charset=utf8mb4',
        $m['host'],
        $m['port'],
        $m['name']
    );
    return new PDO($dsn, $m['user'], $m['pass'], [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]);
}

function hr360_pdo_tenant(array $tenant): PDO
{
    $dsn = sprintf(
        'mysql:host=%s;port=3306;dbname=%s;charset=utf8mb4',
        $tenant['db_host'],
        $tenant['db_name']
    );
    return new PDO($dsn, $tenant['db_user'], $tenant['db_password'], [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]);
}

function hr360_resolve_tenant(string $subdomain): ?array
{
    $pdo = hr360_pdo_master();
    $st = $pdo->prepare(
        "SELECT * FROM tenants WHERE subdomain = ? AND status = 'active' LIMIT 1"
    );
    $st->execute([$subdomain]);
    $row = $st->fetch();
    return $row ?: null;
}

function hr360_issue_token(array $claims): string
{
    $cfg = hr360_config();
    $claims['exp'] = time() + (int) $cfg['token_ttl'];
    $payload = rtrim(strtr(base64_encode(json_encode($claims)), '+/', '-_'), '=');
    $sig = hash_hmac('sha256', $payload, $cfg['token_secret']);
    return $payload . '.' . $sig;
}

function hr360_parse_bearer(): ?array
{
    $header = $_SERVER['HTTP_AUTHORIZATION']
        ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION']
        ?? '';
    if (!preg_match('/Bearer\s+(\S+)/i', $header, $m)) {
        return null;
    }
    $parts = explode('.', $m[1], 2);
    if (count($parts) !== 2) {
        return null;
    }
    [$payload, $sig] = $parts;
    $expected = hash_hmac('sha256', $payload, hr360_config()['token_secret']);
    if (!hash_equals($expected, $sig)) {
        return null;
    }
    $json = base64_decode(strtr($payload, '-_', '+/'));
    $claims = json_decode($json, true);
    if (!is_array($claims) || empty($claims['subdomain'])) {
        return null;
    }
    if (($claims['exp'] ?? 0) < time()) {
        return null;
    }
    return $claims;
}

/** @return array{claims: array, tenant: array, pdo: PDO} */
function hr360_require_auth(): array
{
    $claims = hr360_parse_bearer();
    if ($claims === null) {
        hr360_error('Unauthorized.', 401);
    }
    $tenant = hr360_resolve_tenant((string) $claims['subdomain']);
    if ($tenant === null) {
        hr360_error('Organization not found.', 404);
    }
    return [
        'claims' => $claims,
        'tenant' => $tenant,
        'pdo' => hr360_pdo_tenant($tenant),
    ];
}

function hr360_normalize_permissions(array $rolls, bool $allAccess = false): array
{
    if ($allAccess) {
        return ['all' => true, 'modules' => new stdClass()];
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

function hr360_load_rolls(PDO $pdo, int $employeeId): array
{
    if ($employeeId < 1) {
        return [];
    }
    $st = $pdo->prepare(
        'SELECT d.rolls FROM employee e
         LEFT JOIN designation d ON d.designation_id = e.designation
         WHERE e.employee_id = ? LIMIT 1'
    );
    $st->execute([$employeeId]);
    $row = $st->fetch();
    if (!$row || empty($row['rolls'])) {
        return [];
    }
    $rolls = @unserialize($row['rolls']);
    return is_array($rolls) ? $rolls : [];
}

function hr360_verify_password(string $plain, string $stored): bool
{
    if ($stored !== '' && password_verify($plain, $stored)) {
        return true;
    }
    if ($stored !== '' && $stored === $plain) {
        return true;
    }
    if ($stored !== '' && md5($plain) === $stored) {
        return true;
    }
    return false;
}
