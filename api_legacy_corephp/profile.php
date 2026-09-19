<?php

require_once __DIR__ . '/bootstrap.php';

function hr360_profile_get(): void
{
    $auth = hr360_require_auth();
    $pdo = $auth['pdo'];
    $uid = (int) ($auth['claims']['employee_id'] ?? 0);
    if ($uid < 1) {
        hr360_error('No employee profile.', 404);
    }

    $st = $pdo->prepare(
        'SELECT e.*,
                d.name AS designation_name,
                dep.name AS department_name,
                s.name AS station_name,
                p.name AS project_name,
                lm.name AS line_manager_name
         FROM employee e
         LEFT JOIN designation d ON d.designation_id = e.designation
         LEFT JOIN department dep ON dep.department_id = e.department
         LEFT JOIN station s ON s.station_id = e.station
         LEFT JOIN project p ON p.project_id = e.project
         LEFT JOIN employee lm ON lm.employee_id = e.line_manager
         WHERE e.employee_id = ?
         LIMIT 1'
    );
    $st->execute([$uid]);
    $e = $st->fetch();
    if (!$e) {
        hr360_error('Employee not found.', 404);
    }

    hr360_ok([
        'profile' => [
            'employee_id' => (int) $e['employee_id'],
            'name' => (string) $e['name'],
            'user_name' => (string) ($e['user_name'] ?? ''),
            'email' => (string) ($e['email'] ?? ''),
            'phone' => (string) ($e['phone'] ?? ''),
            'cnic' => (string) ($e['cnic'] ?? ''),
            'employee_code' => (string) ($e['employee_code'] ?? ''),
            'designation_id' => (int) ($e['designation'] ?? 0),
            'designation_name' => (string) ($e['designation_name'] ?? ''),
            'department_name' => (string) ($e['department_name'] ?? ''),
            'station_name' => (string) ($e['station_name'] ?? ''),
            'project_name' => (string) ($e['project_name'] ?? ''),
            'line_manager_name' => (string) ($e['line_manager_name'] ?? ''),
            'profile_picture' => $e['profile_picture'] ?? null,
            'status' => (int) ($e['status'] ?? 0),
        ],
    ]);
}

function hr360_profile_update(): void
{
    $auth = hr360_require_auth();
    $pdo = $auth['pdo'];
    $uid = (int) ($auth['claims']['employee_id'] ?? 0);
    if ($uid < 1) {
        hr360_error('No employee profile.', 404);
    }

    $body = hr360_body();
    $email = trim((string) ($body['email'] ?? ''));
    $phone = trim((string) ($body['phone'] ?? ''));

    $st = $pdo->prepare('UPDATE employee SET email = ?, phone = ? WHERE employee_id = ?');
    $st->execute([$email !== '' ? $email : null, $phone !== '' ? $phone : null, $uid]);

    hr360_ok(['message' => 'Profile updated.']);
}
