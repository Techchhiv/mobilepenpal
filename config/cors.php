<?php

return [
    'paths' => ['api/*', 'sanctum/csrf-cookie', 'auth/google', 'auth/google/callback','storage/*'],
    'allowed_methods' => ['*'],
       'allowed_origins' => [
        
        'http://localhost:3000',        
        
    ],
    'allowed_headers' => ['*'],
    'exposed_headers' => [],
    'max_age' => 0,
    'supports_credentials' => false,

];
