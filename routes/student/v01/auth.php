<?php

use App\Http\Controllers\Student\V01\AuthController;
use App\Http\Controllers\Student\V01\UserController;
use Illuminate\Support\Facades\Route;


Route::prefix('auth')->group(function () {
    Route::get('/logout', [AuthController::class, 'logout']);
    Route::get('/check', [AuthController::class, 'check']);
});

Route::prefix('profile')->group(function() {
    Route::get('', [UserController::class, 'profile']);
    Route::put('', [UserController::class, 'update']);
    Route::put('/password', [UserController::class, 'updatePassword']);
    Route::put('/update-pin', [UserController::class, 'updateParentPin']);
    Route::post('/switch-mode', [UserController::class, 'switchMode']);
    Route::get('/check-pin', [UserController::class, 'checkParentPin']);
});
