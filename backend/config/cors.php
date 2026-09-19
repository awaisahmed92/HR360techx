<?php

return [
    'paths' => ['api/*', 'sanctum/csrf-cookie', 'up'],

    'allowed_methods' => ['*'],

    'allowed_origins' => array_values(array_filter(array_map(
        'trim',
        explode(',', (string) env(
            'CORS_ALLOWED_ORIGINS',
            'https://hr360techx.com,https://www.hr360techx.com,http://localhost,http://127.0.0.1'
        ))
    ))),

    'allowed_origins_patterns' => [
        '#^https://([a-z0-9-]+\.)?hr360techx\.com$#i',
        '#^http://localhost(:\d+)?$#i',
        '#^http://127\.0\.0\.1(:\d+)?$#i',
        '#^http://10\.0\.2\.2(:\d+)?$#i',
        '#^http://192\.168\.\d{1,3}\.\d{1,3}(:\d+)?$#i',
    ],

    'allowed_headers' => ['*'],

    'exposed_headers' => [],

    'max_age' => 3600,

    'supports_credentials' => false,
];
