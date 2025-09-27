<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\{
    AuthController,
    GoogleAuthController,
    CategoryController,
    ProductController,
    ProductShareController,
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

    // Route to get authenticated user info for all roles
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);

    /* -------------------------------
       Admin Routes
    --------------------------------*/
    Route::prefix('admin')->group(function () {

        // Schools routes → accessible by Super Admin OR Client Manager
        Route::middleware(['permission:menu.manage_clients'])->group(function () {
            Route::get('/schools/generate-key', [SchoolController::class, 'generateKey']);
            Route::apiResource('schools', SchoolController::class)->only(['index', 'store', 'update', 'destroy']);
            Route::get('/schools/{school}/subscriptions', [SubscriptionController::class, 'index']);
            Route::post('/schools/{school}/subscriptions', [SubscriptionController::class, 'store']);
        });

        Route::middleware(['role:super-admin'])->group(function () {
            Route::apiResource('users', AdminUserController::class);
            Route::apiResource('roles', AdminRoleController::class)->only(['index', 'store', 'update', 'destroy']);
            Route::apiResource('permissions', AdminPermissionController::class)->only(['index', 'store', 'update', 'destroy']);
        });
    });
});
