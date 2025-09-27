<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\{
    AuthController,
    GoogleAuthController,
    OrdersController,
    AdminUserController,
    AdminRoleController,
    AdminPermissionController,
    SchoolController,
    SubscriptionController
};

/* -------------------------------
   Public Routes
--------------------------------*/

Route::post('/register', [AuthController::class, 'register'])->middleware('throttle:20,1');
Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:30,1');

Route::get('/auth/google/redirect', [GoogleAuthController::class, 'redirectToGoogle']);
Route::get('/auth/google/callback', [GoogleAuthController::class, 'handleGoogleCallback']);
Route::post('/logout', [AuthController::class, 'logout']);

/* -------------------------------
   Authenticated Routes
--------------------------------*/
Route::middleware('auth:api')->group(function () {

    // Authenticated user info (all users)
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);

    /* -------------------------------
       Admin Routes
    --------------------------------*/
    Route::prefix('admin')->group(function () {

        // Schools → Super Admin OR Client Manager
        Route::middleware(['permission:menu.manage_clients'])->group(function () {
            Route::get('/schools/generate-key', [SchoolController::class, 'generateKey']);
            Route::apiResource('schools', SchoolController::class)->only(['index', 'store', 'update', 'destroy']);
           
        });

          Route::middleware(['permission:menu.payments'])->group(function () {
            Route::get('/schools/{school}/subscriptions', [SubscriptionController::class, 'index']);
            Route::post('/schools/{school}/subscriptions', [SubscriptionController::class, 'store']);
        });

        // Users / Roles / Permissions → anyone with the correct permissions
        Route::middleware(['auth:api', 'permission:users.manage|roles.manage|permissions.manage'])->group(function () {
            Route::apiResource('users', AdminUserController::class)->only(['index', 'store', 'update', 'destroy']);
            Route::apiResource('roles', AdminRoleController::class)->only(['index', 'store', 'update', 'destroy']);
            Route::apiResource('permissions', AdminPermissionController::class)->only(['index', 'store', 'update', 'destroy']);
        });
    });



    /* -------------------------------
       School Routes (School Admin with Permissions)
    --------------------------------*/
    Route::prefix('school')->group(function () {

        // School Users / Roles / Permissions → anyone with correct permission
        Route::middleware(['permission:users.manage|roles.manage|permissions.manage'])->group(function () {
            Route::apiResource('users', AdminUserController::class)->only(['index', 'store', 'update', 'destroy']);
            Route::apiResource('roles', AdminRoleController::class)->only(['index', 'store', 'update', 'destroy']);
            Route::apiResource('permissions', AdminPermissionController::class)->only(['index', 'store', 'update', 'destroy']);
        });
    });
});
