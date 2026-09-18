<?php
/**
 * HR360 Flutter replica — API config (this project only).
 * Uses dedicated DBs created by database/setup.bat
 */
return [
    'master' => [
        'host' => getenv('HR360_MASTER_HOST') ?: 'localhost',
        'name' => getenv('HR360_MASTER_DB') ?: 'hr360_master',
        'user' => getenv('HR360_MASTER_USER') ?: 'root',
        'pass' => getenv('HR360_MASTER_PASS') !== false
            ? (string) getenv('HR360_MASTER_PASS')
            : '',
        'port' => (int) (getenv('HR360_MASTER_PORT') ?: 3306),
    ],
    'token_secret' => getenv('HR360_TOKEN_SECRET') ?: 'hr360-flutter-api-dev-secret-change-me',
    'token_ttl' => 60 * 60 * 12,
    'cors_origin' => '*',
];
