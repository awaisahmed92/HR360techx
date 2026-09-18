<?php
/**
 * HR360 Flutter replica — standalone REST entrypoint.
 * URL: http://localhost/HR360techx/api/...
 *
 * This is independent of D:\xampp\htdocs\hr (original PHP app).
 */

require_once __DIR__ . '/bootstrap.php';
require_once __DIR__ . '/auth.php';
require_once __DIR__ . '/leave.php';

hr360_cors();

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

$uri = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';
// Normalize when served from /HR360techx/api/...
$uri = preg_replace('#^.*/api#', '', $uri) ?: '/';
$uri = '/' . trim($uri, '/');
$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

$routes = [
    'POST /auth/login' => 'hr360_auth_login',
    'GET /auth/me' => 'hr360_auth_me',
    'GET /leave/types' => 'hr360_leave_types',
    'GET /leave' => 'hr360_leave_index',
    'POST /leave/apply' => 'hr360_leave_apply',
    'POST /leave/approve' => fn () => hr360_leave_act('approve'),
    'POST /leave/reject' => fn () => hr360_leave_act('reject'),
];

// Also support /api/v1/... prefixes for Flutter client compatibility
$key = $method . ' ' . $uri;
$keyV1 = $method . ' ' . preg_replace('#^/v1#', '', $uri);

if (isset($routes[$key])) {
    ($routes[$key])();
} elseif (isset($routes[$keyV1])) {
    ($routes[$keyV1])();
} elseif ($uri === '/' || $uri === '') {
    hr360_ok([
        'name' => 'HR360 Flutter API',
        'version' => '1.0',
        'note' => 'Standalone API for the Flutter replica (not the original PHP HR app).',
        'endpoints' => array_keys($routes),
    ]);
} else {
    hr360_error('Not found: ' . $method . ' ' . $uri, 404);
}
