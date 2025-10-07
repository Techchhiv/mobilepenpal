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
    SchoolDashboardController,
    SchoolPermissionController,
    SchoolRoleController,
    SchoolUserController,
    StudentController,
    SubscriptionController,
    TeacherController
};

/* -------------------------------
   Public Routes
--------------------------------*/

Route::post('/register', [AuthController::class, 'register'])->middleware('throttle:20,1');
Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:30,1');
Route::post('/teacher/login', [AuthController::class, 'teacherLogin']);


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



Route::prefix('school')->middleware('auth:api')->group(function() {

    // School dashboard (any school-admin)

    // Manage teachers (school-admin only)
    Route::middleware('permission:teachers.view|teachers.create|teachers.update|teachers.delete')->group(function() {
        Route::get('/teachers', [TeacherController::class, 'index']);
        Route::post('/teachers', [TeacherController::class, 'store']);
        Route::put('/teachers/{teacher}', [TeacherController::class, 'update']);
        Route::delete('/teachers/{teacher}', [TeacherController::class, 'destroy']);
    });

    // Manage students
    Route::middleware('permission:parents.view|children.view|children.create')->group(function() {
        Route::get('/students', [StudentController::class, 'index']);
        Route::post('/students', [StudentController::class, 'store']);
    });

    // Manage school users / roles / permissions (school-admin only)
    Route::middleware('permission:users.manage|roles.manage|permissions.manage')->group(function () {
        Route::apiResource('users', SchoolUserController::class)->only(['index','store','update','destroy']);
        Route::apiResource('roles', SchoolRoleController::class)->only(['index','store','update','destroy']);
        Route::apiResource('permissions', SchoolPermissionController::class)->only(['index','store','update','destroy']);
    });
});


});
