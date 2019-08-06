<?php return [
    'app' => [
        'directory' => dirname(__DIR__),
    ],
    'providers' => [
        'templates' => [
            'provider' => Imarc\Ops\Dashboard\Providers\PlatesProvider::class,
            'config' => [
                'path' => dirname(__DIR__) . '/resources/templates',
            ],
        ],
    ]
];
