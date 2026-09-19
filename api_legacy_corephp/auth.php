<?php

require_once __DIR__ . '/bootstrap.php';

function hr360_auth_login(): void
{
    $payload = hr360_body();
    $subdomain = trim((string) ($payload['subdomain'] ?? ''));
    $username = trim((string) ($payload['username'] ?? ''));
    $password = (string) ($payload['password'] ?? '');

    if ($subdomain === '' || $username === '' || $password === '') {
        hr360_error('Subdomain, username and password are required.', 422);
    }

    try {
        $tenant = hr360_resolve_tenant($subdomain);
        if ($tenant === null) {
            hr360_error('Organization not found or inactive.', 404);
        }
        if (isset($tenant['hr_app']) && (int) $tenant['hr_app'] !== 1) {
            hr360_error('HR application is disabled for this organization.', 403);
        }

        $pdo = hr360_pdo_tenant($tenant);
        $st = $pdo->prepare(
            'SELECT * FROM employee
             WHERE (user_name = ? OR email = ?)
             LIMIT 1'
        );
        $st->execute([$username, $username]);
        $user = $st->fetch();

        if (!$user || !hr360_verify_password($password, (string) ($user['password'] ?? ''))) {
            hr360_error('Invalid credentials.', 401);
        }

        $employeeId = (int) ($user['employee_id'] ?? 0);
        $userStatus = (int) ($user['status'] ?? 0);
        $allAccess = $userStatus === 2;
        $rolls = $allAccess ? [] : hr360_load_rolls($pdo, $employeeId);

        $designationId = (int) ($user['designation'] ?? 0);
        $designationName = '';
        if ($designationId > 0) {
            $d = $pdo->prepare('SELECT name FROM designation WHERE designation_id = ? LIMIT 1');
            $d->execute([$designationId]);
            $dr = $d->fetch();
            $designationName = (string) ($dr['name'] ?? '');
        }

        $company = $pdo->query('SELECT * FROM company LIMIT 1')->fetch() ?: [];

        $token = hr360_issue_token([
            'subdomain' => $subdomain,
            'employee_id' => $employeeId,
            'user_status' => $userStatus,
            'is_superuser' => 0,
        ]);

        hr360_ok([
            'token' => $token,
            'user' => [
                'employee_id' => $employeeId,
                'name' => (string) ($user['name'] ?? ''),
                'user_name' => (string) ($user['user_name'] ?? $username),
                'email' => (string) ($user['email'] ?? ''),
                'designation_id' => $designationId,
                'designation_name' => $designationName,
                'user_status' => $userStatus,
                'is_first_login' => (int) ($user['is_first_login'] ?? 0),
                'profile_picture' => $user['profile_picture'] ?? null,
                'is_superuser' => false,
            ],
            'company' => [
                'name' => (string) ($company['hr_company_name'] ?? $company['name'] ?? $subdomain),
                'code' => (string) ($company['code'] ?? ''),
                'logo' => $company['hr_logo'] ?? $company['logo'] ?? null,
                'currency' => (string) ($company['currency'] ?? 'PKR'),
                'date_format' => (string) ($company['hr_date_format'] ?? 'd-m-Y'),
                'subdomain' => $subdomain,
            ],
            'permissions' => hr360_normalize_permissions($rolls, $allAccess),
        ]);
    } catch (Throwable $e) {
        hr360_error('Login failed: ' . $e->getMessage(), 500);
    }
}

function hr360_auth_me(): void
{
    $auth = hr360_require_auth();
    $claims = $auth['claims'];
    $pdo = $auth['pdo'];
    $employeeId = (int) ($claims['employee_id'] ?? 0);
    $userStatus = (int) ($claims['user_status'] ?? 0);
    $allAccess = !empty($claims['is_superuser']) || $userStatus === 2;

    $user = [];
    if ($employeeId > 0) {
        $st = $pdo->prepare('SELECT * FROM employee WHERE employee_id = ? LIMIT 1');
        $st->execute([$employeeId]);
        $user = $st->fetch() ?: [];
    }

    $designationId = (int) ($user['designation'] ?? 0);
    $designationName = '';
    if ($designationId > 0) {
        $d = $pdo->prepare('SELECT name FROM designation WHERE designation_id = ? LIMIT 1');
        $d->execute([$designationId]);
        $dr = $d->fetch();
        $designationName = (string) ($dr['name'] ?? '');
    }

    $company = $pdo->query('SELECT * FROM company LIMIT 1')->fetch() ?: [];
    $rolls = $allAccess ? [] : hr360_load_rolls($pdo, $employeeId);

    hr360_ok([
        'user' => [
            'employee_id' => $employeeId,
            'name' => (string) ($user['name'] ?? ''),
            'user_name' => (string) ($user['user_name'] ?? ''),
            'email' => (string) ($user['email'] ?? ''),
            'designation_id' => $designationId,
            'designation_name' => $designationName,
            'user_status' => $userStatus,
            'is_first_login' => (int) ($user['is_first_login'] ?? 0),
            'profile_picture' => $user['profile_picture'] ?? null,
            'is_superuser' => !empty($claims['is_superuser']),
        ],
        'company' => [
            'name' => (string) ($company['hr_company_name'] ?? $company['name'] ?? $claims['subdomain']),
            'code' => (string) ($company['code'] ?? ''),
            'logo' => $company['hr_logo'] ?? $company['logo'] ?? null,
            'currency' => (string) ($company['currency'] ?? 'PKR'),
            'date_format' => (string) ($company['hr_date_format'] ?? 'd-m-Y'),
            'subdomain' => (string) $claims['subdomain'],
        ],
        'permissions' => hr360_normalize_permissions($rolls, $allAccess),
    ]);
}
