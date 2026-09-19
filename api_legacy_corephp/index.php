<?php
/**
 * HR360 Flutter replica — standalone REST entrypoint.
 * URL: http://localhost/HR360techx/api/...
 */

require_once __DIR__ . '/bootstrap.php';
require_once __DIR__ . '/auth.php';
require_once __DIR__ . '/leave.php';
require_once __DIR__ . '/profile.php';
require_once __DIR__ . '/attendance.php';
require_once __DIR__ . '/self_service.php';

hr360_cors();

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

$uri = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';
$uri = preg_replace('#^.*/api#', '', $uri) ?: '/';
$uri = '/' . trim($uri, '/');
$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

$routes = [
    'POST /auth/login' => 'hr360_auth_login',
    'GET /auth/me' => 'hr360_auth_me',

    'GET /profile' => 'hr360_profile_get',
    'POST /profile' => 'hr360_profile_update',

    'GET /leave/types' => 'hr360_leave_types',
    'GET /leave' => 'hr360_leave_index',
    'POST /leave/apply' => 'hr360_leave_apply',
    'POST /leave/approve' => fn () => hr360_leave_act('approve'),
    'POST /leave/reject' => fn () => hr360_leave_act('reject'),

    'GET /attendance/today' => 'hr360_attendance_today',
    'GET /attendance' => 'hr360_attendance_list',
    'POST /attendance/punch' => 'hr360_attendance_punch',

    'GET /travel' => 'hr360_travel_list',
    'POST /travel/apply' => 'hr360_travel_apply',
    'POST /travel/approve' => fn () => hr360_travel_act('approve'),
    'POST /travel/reject' => fn () => hr360_travel_act('reject'),

    'GET /timesheet' => 'hr360_timesheet_list',
    'POST /timesheet/apply' => 'hr360_timesheet_apply',
    'POST /timesheet/approve' => fn () => hr360_timesheet_act('approve'),
    'POST /timesheet/reject' => fn () => hr360_timesheet_act('reject'),

    'GET /approvals/inbox' => 'hr360_approvals_inbox',
];

$key = $method . ' ' . $uri;
$keyV1 = $method . ' ' . preg_replace('#^/v1#', '', $uri);

if (isset($routes[$key])) {
    ($routes[$key])();
} elseif (isset($routes[$keyV1])) {
    ($routes[$keyV1])();
} elseif ($uri === '/' || $uri === '') {
    hr360_ok([
        'name' => 'HR360 Flutter API',
        'version' => '1.1',
        'endpoints' => array_keys($routes),
    ]);
} else {
    hr360_error('Not found: ' . $method . ' ' . $uri, 404);
}
