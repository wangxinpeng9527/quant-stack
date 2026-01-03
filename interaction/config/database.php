<?php
return [
    'default' => 'mysql',

    'connections' => [
        'mysql' => [
            'driver'    => 'mysql',
            'host'      => env('DB_HOST', 'mysql'),
            'port'      => env('DB_PORT', 3306),
            'database'  => env('DB_DATABASE', 'quant'),
            'username'  => env('DB_USERNAME', 'quant'),
            'password'  => env('DB_PASSWORD', 'quant'),
            'charset'   => 'utf8mb4',
            'collation' => 'utf8mb4_unicode_ci',
            'prefix'    => '',
        ],
    ],
];
