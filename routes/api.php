<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\{
    AuthController, GoogleAuthController, CategoryController, ProductController,
    ProductShareController, OrdersController, AdminUserController,
    AdminRoleController, AdminPermissionController
};

/* Public */
Route::post('/register', [AuthController::class, 'register'])->middleware('throttle:20,1');
Route::post('/login',    [AuthController::class, 'login'])->middleware('throttle:30,1');

Route::apiResource('categories', CategoryController::class)->only(['index','show']);
Route::apiResource('products',   ProductController::class)->only(['index','show']);
Route::get('share/p/{slug}', [ProductShareController::class, 'show']);

Route::get('products/slug/{slug}', [ProductController::class, 'showBySlug']); // <-- ADD

Route::get('productDetailByProduct/{id}', [ProductController::class, 'productDetailByProduct']);
Route::get('productsByCategory/{categoryId}', [ProductController::class, 'filterByCategory']);
Route::get('productsByCategorySlug/{slug}', [ProductController::class, 'filterByCategorySlug']);


Route::get('/auth/google/redirect', [GoogleAuthController::class, 'redirectToGoogle']);
Route::get('/auth/google/callback', [GoogleAuthController::class, 'handleGoogleCallback']);
Route::post('/logout', [AuthController::class, 'logout']);

Route::middleware('auth:api')->group(function () {
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::apiResource('orders', OrdersController::class);

    Route::prefix('admin')->middleware(['auth:api','role:super-admin,api'])->group(function () {
        Route::apiResource('users', AdminUserController::class);
        Route::apiResource('roles', AdminRoleController::class)->only(['index','store','update','destroy']);
        Route::apiResource('permissions', AdminPermissionController::class)->only(['index','store','update','destroy']);

        Route::apiResource('categories', CategoryController::class)->only(['store','update','destroy']);
        Route::apiResource('products',   ProductController::class)->only(['store','update','destroy']);
       
    });
});
