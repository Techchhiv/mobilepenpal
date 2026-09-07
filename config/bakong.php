<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Bakong Open API & KHQR Configuration
    |--------------------------------------------------------------------------
    |
    | Configuration for National Bank of Cambodia (NBC) Bakong payment API
    | and dynamic EMVCo KHQR generation.
    |
    */

    // Bakong Open API Base URL (SIT sandbox or Production)
    'api_url' => env('BAKONG_API_URL', 'https://sit-api-bakong.nbc.org.kh/v1'),

    // Bearer Developer/Partner Token provided by NBC Bakong
    'api_token' => env('BAKONG_API_TOKEN', ''),

    // Individual Bakong Account ID (e.g., 'your_name@aclb' or mobile number '855xxxxxxxxx')
    'account_id' => env('BAKONG_ACCOUNT_ID', '019165576@abab'),

    // Payee / Merchant Display Name
    'merchant_name' => env('BAKONG_MERCHANT_NAME', 'Khmer PenPal'),

    // City of Operation
    'merchant_city' => env('BAKONG_MERCHANT_CITY', 'Phnom Penh'),

    // Default Currency: 'USD' or 'KHR'
    'currency' => env('BAKONG_CURRENCY', 'USD'),

    // QR Code Expiration in Seconds (e.g. 10 minutes = 600 seconds)
    'qr_expiration_seconds' => (int) env('BAKONG_QR_EXPIRATION', 600),

    // Enable Mock/Simulation Mode for testing without live bank transfers
    'simulation_mode' => env('BAKONG_SIMULATION_MODE', true),
];
