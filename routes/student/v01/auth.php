<?php

use App\Http\Controllers\Student\V01\AuthController;
use App\Http\Controllers\Student\V01\ClassroomController;
use App\Http\Controllers\Student\V01\UserController;
use App\Http\Controllers\Student\V01\WorldController;
use App\Http\Controllers\Student\V01\ShopController;
use Illuminate\Support\Facades\Route;


Route::prefix('auth')->group(function () {
    Route::get('/logout', [AuthController::class, 'logout']);
    Route::get('/check', [AuthController::class, 'check']);
});

Route::prefix('profile')->group(function () {
    Route::get('', [UserController::class, 'profile']);
    Route::put('', [UserController::class, 'update']);
    Route::post('/upload-avatar', [UserController::class, 'updateImage']);
    Route::put('/password', [UserController::class, 'updatePassword']);
    Route::put('/update-pin', [UserController::class, 'updateParentPin']);
    Route::post('/switch-mode', [UserController::class, 'switchMode']);
    Route::get('/check-pin', [UserController::class, 'checkParentPin']);
    Route::get('/summary/daily', [UserController::class, 'dailySummary']);
    Route::get('/summary/weekly', [UserController::class, 'weeklySummary']);
    Route::get('/summary/monthly', [UserController::class, 'monthlySummary']);
});

Route::prefix('shop')->group(function () {
    Route::post('/purchase-avatar', [ShopController::class, 'purchaseAvatar']);
});

Route::prefix('worlds')->group(function () {
    Route::get('', [WorldController::class, 'index']);
    Route::get('/exercises', [WorldController::class, 'exercises']);
    Route::get('{id}', [WorldController::class, 'showWorld']);
    Route::get('/level/{levelId}', [WorldController::class, 'showLevel']);
    Route::get('/level/stage/{stageId}', [WorldController::class, 'showStage']);
    Route::post('/exercise/submit', [WorldController::class, 'submitExerciseBatch']);
});

Route::prefix('classrooms')->group(function (){
    Route::get('', [ClassroomController::class, 'index']);
    Route::get('{classroom}', [ClassroomController::class, 'show']);
    Route::post('/join', [ClassroomController::class, 'joinByCode']);
});
