<?php

use App\Http\Controllers\Student\V01\AuthController;
use Illuminate\Support\Facades\Route;


Route::prefix('auth')->group(function () {
    Route::get('/logout', [AuthController::class, 'logout']);
    Route::get('/check', [AuthController::class, 'check']);
});
