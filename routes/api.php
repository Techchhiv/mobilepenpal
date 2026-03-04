<?php

use App\Http\Controllers\Admin\V01\LevelController;
use App\Http\Controllers\Admin\V01\SubscriptionController as AdminSubscriptionController;
use App\Http\Controllers\Admin\V01\WorldController;
use App\Http\Controllers\School\V01\WorldController as SchoolWorldController;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\{
    AuthController,
    GoogleAuthController,
    AdminUserController,
    AdminRoleController,
    AdminPermissionController,
    ClassroomController,
    SchoolController,
    SchoolDashboardController,
    SchoolPermissionController,
    SchoolRoleController,
    SchoolUserController,
    StudentController,
    SubscriptionController,
    TeacherController
};
use App\Http\Controllers\Admin\V01\ExerciseController;
use App\Http\Controllers\Admin\V01\StageController;
use App\Http\Controllers\Admin\V01\StageExerciseController;

/* -------------------------------
   Public Routes
--------------------------------*/

Route::post('/register', [AuthController::class, 'register'])->middleware('throttle:20,1');
Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:30,1');
Route::post('/teacher/login', [AuthController::class, 'teacherLogin']);


Route::get('/auth/google/redirect', [GoogleAuthController::class, 'redirectToGoogle']);
Route::get('/auth/google/callback', [GoogleAuthController::class, 'handleGoogleCallback']);
Route::post('/logout', [AuthController::class, 'logout']);

// Public schools list for student registration
Route::get('/schools/list', [SchoolController::class, 'publicList']);

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
    Route::prefix('admin')->name('admin.')->group(function () {

        Route::get('/reports/schools', [\App\Http\Controllers\Admin\V01\DashboardController::class, 'index']);

        // Schools
        Route::middleware(['permission:menu.manage_clients'])->group(function () {
            Route::get('/schools/generate-key', [SchoolController::class, 'generateKey']);
            Route::apiResource('schools', SchoolController::class)->only(['index', 'store', 'update', 'destroy']);
        });

        Route::middleware(['permission:menu.payments'])->group(function () {
            // New manual activation routes (using the new Admin V01 controller)
            Route::post('/subscriptions/school/{schoolId}/activate', [AdminSubscriptionController::class, 'activateSchool']);
            Route::post('/subscriptions/student/{studentId}/activate', [AdminSubscriptionController::class, 'activateStudent']);

            // Renewal routes
            Route::post('/subscriptions/school/{schoolId}/renew', [AdminSubscriptionController::class, 'renewSchool']);
            Route::post('/subscriptions/student/{studentId}/renew', [AdminSubscriptionController::class, 'renewStudent']);

            // Listing routes
            Route::get('/subscriptions/schools', [AdminSubscriptionController::class, 'schools']);
            Route::get('/subscriptions/students', [AdminSubscriptionController::class, 'students']);

            Route::get('/subscriptions/active', [AdminSubscriptionController::class, 'active']);

            // Existing routes (you can keep or remove depending on if you want to use the new one exclusively)
            Route::get('/schools/{school}/subscriptions', [SubscriptionController::class, 'index']);
            Route::post('/schools/{school}/subscriptions', [SubscriptionController::class, 'store']);
        });

        // Users
        Route::middleware(['auth:api', 'permission:users.manage|roles.manage|permissions.manage'])->group(function () {
            Route::apiResource('users', AdminUserController::class)->only(['index', 'store', 'update', 'destroy']);
            Route::apiResource('roles', AdminRoleController::class)->only(['index', 'store', 'update', 'destroy']);
            Route::apiResource('permissions', AdminPermissionController::class)->only(['index', 'store', 'update', 'destroy']);
        });

        Route::prefix('worlds')->group(function () {
            Route::get('', [WorldController::class, 'index']);
            Route::post('', [WorldController::class, 'store']);
            Route::get('/{id}', [WorldController::class, 'show']);
            Route::put('/{id}', [WorldController::class, 'update']);
            Route::put('/{id}/toggle', [WorldController::class, 'toggle']);
            Route::put('/{id}/reorder', [WorldController::class, 'reorder']);
            Route::post('/{id}/unlock-student', [WorldController::class, 'unlockForStudent']);

            Route::post('/{id}/assign', [WorldController::class, 'assignToSchools']);
            Route::post('/{id}/unassign', [WorldController::class, 'unassignFromSchools']);
            Route::put('/{id}/reorder-school', [WorldController::class, 'reorderForSchool']);

            Route::get('{worldId}/levels', [LevelController::class, 'index']);
            Route::post('{worldId}/levels', [LevelController::class, 'store']);
        });

        Route::prefix('levels')->group(function () {
            Route::get('', [LevelController::class, 'indexGlobal']);
            Route::post('', [LevelController::class, 'storeGlobal']);

            Route::get('/{id}', [LevelController::class, 'show']);
            Route::put('/{id}', [LevelController::class, 'update']);
            Route::put('/{id}/toggle', [LevelController::class, 'toggle']);
            Route::put('/{id}/reorder', [LevelController::class, 'reorder']);

            Route::get('/{levelId}/stages', [StageController::class, 'index']);
            Route::post('/{levelId}/stages', [StageController::class, 'store']);
        });

        Route::prefix('stages')->group(function () {
            Route::get('', [StageController::class, 'indexGlobal']);
            Route::post('', [StageController::class, 'storeGlobal']);

            Route::get('/{id}', [StageController::class, 'show']);
            Route::put('/{id}', [StageController::class, 'update']);
            Route::put('/{id}/toggle', [StageController::class, 'toggle']);
            Route::put('/{id}/reorder', [StageController::class, 'reorder']);

            Route::get('/{stageId}/exercises', [StageExerciseController::class, 'index']);
            Route::post('/{stageId}/exercises', [StageExerciseController::class, 'store']);
        });

        Route::prefix('exercises')->group(function () {
            Route::get('', [ExerciseController::class, 'index']);
            Route::post('', [ExerciseController::class, 'store']);
            Route::get('/{id}', [ExerciseController::class, 'show']);
            Route::put('/{id}', [ExerciseController::class, 'update']);
        });

        Route::prefix('stage-exercises')->group(function () {
            Route::get('/{id}', [StageExerciseController::class, 'show']);
            Route::put('/{id}', [StageExerciseController::class, 'update']);
            Route::put('/{id}/toggle', [StageExerciseController::class, 'toggle']);
            Route::put('/{id}/reorder', [StageExerciseController::class, 'reorder']);
        });
    });


    Route::prefix('school')->name('school.')->middleware('auth:api')->group(function () {

        // School dashboard (any school-admin)
        Route::get('/dashboard', [\App\Http\Controllers\School\V01\DashboardController::class, 'index']);

        // Manage teachers (school-admin only)
        Route::middleware('permission:teachers.view|teachers.create|teachers.update|teachers.delete')->group(function () {
            Route::get('/teachers', [TeacherController::class, 'index']);
            Route::get('/teachers/{teacher}', [TeacherController::class, 'show']);
            Route::post('/teachers', [TeacherController::class, 'store']);
            Route::put('/teachers/{teacher}', [TeacherController::class, 'update']);
            Route::delete('/teachers/{teacher}', [TeacherController::class, 'destroy']);
        });

        // Manage students
        Route::middleware('permission:parents.view|children.view|children.create|children.update')->group(function () {
            Route::get('/students', [StudentController::class, 'index']);
            Route::post('/students', [StudentController::class, 'store']);
            Route::get('/students/{student}', [StudentController::class, 'show']);
            Route::put('/students/{student}', [StudentController::class, 'update']);
        });

        // Manage Classroom
        Route::middleware('permission:classrooms.view|classrooms.create|classrooms.update')->group(function () {
            Route::get('classrooms', [ClassroomController::class, 'index']);
            Route::post('classrooms', [ClassroomController::class, 'create']);
            Route::get('classrooms/{classroom}', [ClassroomController::class, 'show']);
            Route::put('classrooms/{classroom}', [ClassroomController::class, 'update']);
            Route::delete('classrooms/{classroom}', [ClassroomController::class, 'archive']);

            Route::post('classrooms/{classroom}/regenerate-join-code', [ClassroomController::class, 'regenerateJoinCode']);
            Route::post('classrooms/{classroom}/students/{student}/complete', [ClassroomController::class, 'completeStudent']);

            // manage enrollments
            Route::get('classrooms/{classroom}/students/{student}', [ClassroomController::class, 'students']);
            Route::post('classrooms/{classroom}/students/{student}/remove', [ClassroomController::class, 'removeStudent']);
        });

        Route::prefix('worlds')->group(function () {
            Route::get('', [SchoolWorldController::class, 'index']);
            Route::post('', [SchoolWorldController::class, 'store']);
            Route::get('{id}', [SchoolWorldController::class, 'show']);
            Route::put('{id}', [SchoolWorldController::class, 'update']);
            Route::put('{id}/toggle', [SchoolWorldController::class, 'toggle']);
            Route::put('{id}/reorder', [SchoolWorldController::class, 'reorder']);

            Route::get('{worldId}/levels', [\App\Http\Controllers\School\V01\LevelController::class, 'index']);
            Route::post('{worldId}/levels', [\App\Http\Controllers\School\V01\LevelController::class, 'store']);
        });

        Route::prefix('levels')->group(function () {
            Route::get('{id}', [\App\Http\Controllers\School\V01\LevelController::class, 'show']);
            Route::put('{id}', [\App\Http\Controllers\School\V01\LevelController::class, 'update']);
            Route::put('{id}/toggle', [\App\Http\Controllers\School\V01\LevelController::class, 'toggle']);
            Route::put('{id}/reorder', [\App\Http\Controllers\School\V01\LevelController::class, 'reorder']);

            Route::get('{levelId}/stages', [\App\Http\Controllers\School\V01\StageController::class, 'index']);
            Route::post('{levelId}/stages', [\App\Http\Controllers\School\V01\StageController::class, 'store']);
        });

        Route::prefix('stages')->group(function () {
            Route::get('{id}', [\App\Http\Controllers\School\V01\StageController::class, 'show']);
            Route::put('{id}', [\App\Http\Controllers\School\V01\StageController::class, 'update']);
            Route::put('{id}/toggle', [\App\Http\Controllers\School\V01\StageController::class, 'toggle']);
            Route::put('{id}/reorder', [\App\Http\Controllers\School\V01\StageController::class, 'reorder']);

            Route::get('{stageId}/exercises', [\App\Http\Controllers\School\V01\StageExerciseController::class, 'index']);
            Route::post('{stageId}/exercises', [\App\Http\Controllers\School\V01\StageExerciseController::class, 'store']);
        });

        Route::prefix('stage-exercises')->group(function () {
            Route::put('{id}', [\App\Http\Controllers\School\V01\StageExerciseController::class, 'update']);
            Route::put('{id}/toggle', [\App\Http\Controllers\School\V01\StageExerciseController::class, 'toggle']);
            Route::put('{id}/reorder', [\App\Http\Controllers\School\V01\StageExerciseController::class, 'reorder']);
            Route::delete('{id}', [\App\Http\Controllers\School\V01\StageExerciseController::class, 'destroy']);
        });

        // Manage school users / roles / permissions (school-admin only)
        Route::middleware('permission:users.manage|roles.manage|permissions.manage')->group(function () {
            Route::apiResource('users', SchoolUserController::class)->only(['index', 'store', 'update', 'destroy']);
            Route::apiResource('roles', SchoolRoleController::class)->only(['index', 'store', 'update', 'destroy']);
            Route::apiResource('permissions', SchoolPermissionController::class)->only(['index', 'store', 'update', 'destroy']);
        });
    });
});
