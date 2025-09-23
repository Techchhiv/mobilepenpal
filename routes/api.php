<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\{
    AuthController, GoogleAuthController, CategoryController, ProductController,
    ProductShareController, OrdersController, AdminUserController,
    AdminRoleController, AdminPermissionController,
    SchoolController
};

/* Public */
Route::post('/register', [AuthController::class, 'register'])->middleware('throttle:20,1');
Route::post('/login',    [AuthController::class, 'login'])->middleware('throttle:30,1');



Route::get('/auth/google/redirect', [GoogleAuthController::class, 'redirectToGoogle']);
Route::get('/auth/google/callback', [GoogleAuthController::class, 'handleGoogleCallback']);
Route::post('/logout', [AuthController::class, 'logout']);

Route::middleware('auth:api')->group(function () {
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::apiResource('orders', OrdersController::class);

    Route::prefix('admin')->middleware(['auth:api','role:super-admin,api'])->group(function () {
        Route::get('/schools/generate-key', [SchoolController::class, 'generateKey']); // ✅ new

        Route::apiResource('users', AdminUserController::class);
        Route::apiResource('schools', SchoolController::class);
        Route::apiResource('roles', AdminRoleController::class)->only(['index','store','update','destroy']);
        Route::apiResource('permissions', AdminPermissionController::class)->only(['index','store','update','destroy']);

       
    });
});
