<?php

use App\Http\Controllers\Student\V01\AuthController;
use Illuminate\Support\Facades\Route;

Route::get('/health', function () {
    return response()->json([
        'status' => 'ok',
        'time' => now()->toIso8601String(),
    ], 200);
});

Route::prefix('auth')->group(function () {
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login']);
    Route::post('/login-test', [AuthController::class, 'login_test']);
    Route::post('/verify-otp', [AuthController::class, 'verifyOtp']);
});
