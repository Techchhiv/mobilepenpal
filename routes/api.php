<?php

use App\Http\Controllers\Admin\V01\DashboardController as AdminDashboardController;
use App\Http\Controllers\Admin\V01\ExpenseController;
use App\Http\Controllers\Admin\V01\LevelController;
use App\Http\Controllers\Admin\V01\ReportController;
use App\Http\Controllers\Admin\V01\SubscriptionController as AdminSubscriptionController;
use App\Http\Controllers\Admin\V01\InvoiceController;
use App\Http\Controllers\Admin\V01\StudentController as AdminStudentController;
use App\Http\Controllers\Admin\V01\SystemSettingController;
use App\Http\Controllers\Admin\V01\WorldController;
use App\Http\Controllers\School\V01\WorldController as SchoolWorldController;
use App\Http\Controllers\School\V01\StudentController as SchoolStudentController;
use App\Http\Controllers\School\V01\SchoolBillingController;
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
    SubscriptionController,
    TeacherController,
    UserProfileController
};
use App\Http\Controllers\Admin\V01\ExerciseController;
use App\Http\Controllers\Admin\V01\StageController;
use App\Http\Controllers\Admin\V01\StageExerciseController;
use App\Http\Controllers\Admin\V01\QuestionTemplateController;
use App\Http\Controllers\Admin\V01\AuditLogController;

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

    // User Profile & Settings (all users)
    Route::get('/profile', [UserProfileController::class, 'show']);
    Route::put('/profile', [UserProfileController::class, 'update']);
    Route::put('/profile/password', [UserProfileController::class, 'updatePassword']);

    /* -------------------------------
       Admin Routes
    --------------------------------*/
    Route::prefix('admin')->name('admin.')->group(function () {
        // Admin Dashboard
        Route::get('/dashboard', [AdminDashboardController::class, 'index']);
        Route::get('/dashboard/needs-attention', [AdminDashboardController::class, 'needsAttention']);

        // Expenses CRUD
        Route::middleware(['permission:billing.view|menu.payments'])->group(function () {
            Route::apiResource('expenses', ExpenseController::class);
        });

        Route::middleware(['permission:menu.reports|reports.view'])->prefix('reports')->group(function () {
            Route::get('/schools', [ReportController::class, 'index']);
            Route::get('/schools/export', [ReportController::class, 'export']); // Must be before /{school}
            Route::get('/schools/{school}', [ReportController::class, 'show']);
        });

        // Schools
        Route::middleware(['permission:menu.manage_clients'])->group(function () {
            Route::get('/schools/generate-key', [SchoolController::class, 'generateKey']);
            Route::apiResource('schools', SchoolController::class)->only(['index', 'store', 'update', 'destroy']);
        });

        Route::middleware(['permission:menu.payments'])->group(function () {
            // Subscription activation / renewal (now also creates invoices via SubscriptionBillingService)
            Route::post('/subscriptions/school/{schoolId}/activate', [AdminSubscriptionController::class, 'activateSchool']);
            Route::post('/subscriptions/student/{studentId}/activate', [AdminSubscriptionController::class, 'activateStudent']);

            // Renewal routes
            Route::post('/subscriptions/school/{schoolId}/renew', [AdminSubscriptionController::class, 'renewSchool']);
            Route::post('/subscriptions/student/{studentId}/renew', [AdminSubscriptionController::class, 'renewStudent']);

            // Deactivation / cancellation routes
            Route::post('/subscriptions/school/{schoolId}/deactivate', [AdminSubscriptionController::class, 'deactivateSchool']);
            Route::post('/subscriptions/student/{studentId}/deactivate', [AdminSubscriptionController::class, 'deactivateStudent']);

            // Listing routes
            Route::get('/subscriptions/schools', [AdminSubscriptionController::class, 'schools']);
            Route::get('/subscriptions/students', [AdminSubscriptionController::class, 'students']);
            Route::get('/subscriptions/active', [AdminSubscriptionController::class, 'active']);

            // Legacy route — now proxied through billing service so it also creates invoices
            Route::get('/schools/{school}/subscriptions', [SubscriptionController::class, 'index']);
            Route::post('/schools/{school}/subscriptions', [SubscriptionController::class, 'store']);
        });

        // ── Invoice Routes (billing.view / billing.void_invoice) ──────────────
        Route::middleware(['permission:billing.view|menu.payments'])->group(function () {
            // Plan prices for React activation modal
            Route::get('/invoices/prices', [InvoiceController::class, 'prices']);
            // Paginated list with filters
            Route::get('/invoices', [InvoiceController::class, 'index']);
            // Detail
            Route::get('/invoices/{invoice}', [InvoiceController::class, 'show']);
            // PDF download (authenticated, private)
            Route::get('/invoices/{invoice}/pdf', [InvoiceController::class, 'downloadPdf']);
        });

        // Void requires higher privilege (super-admin or billing.void_invoice)
        Route::middleware(['permission:billing.void_invoice'])->group(function () {
            Route::post('/invoices/{invoice}/void', [InvoiceController::class, 'void']);
        });

        Route::middleware(['permission:menu.subscription'])->group(function () {
            // menu.subscription permission reserved for subscription page visibility
        });

        // System settings — accessible by payment managers and user managers
        Route::middleware(['permission:menu.payments|users.manage'])->group(function () {
            Route::get('/system-settings/{key}', [SystemSettingController::class, 'show']);
            Route::post('/system-settings/{key}', [SystemSettingController::class, 'update']);
            Route::get('/feature-locks', [SystemSettingController::class, 'showFeatureLocks']);
            Route::post('/feature-locks', [SystemSettingController::class, 'updateFeatureLocks']);
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

        Route::prefix('question-templates')->group(function () {
            Route::get('', [QuestionTemplateController::class, 'index']);
            Route::post('', [QuestionTemplateController::class, 'store']);
            Route::get('/{id}', [QuestionTemplateController::class, 'show']);
            Route::put('/{id}', [QuestionTemplateController::class, 'update']);
            Route::delete('/{id}', [QuestionTemplateController::class, 'destroy']);
        });

        Route::prefix('students')->group(function () {
            Route::get('', [AdminStudentController::class, 'index']);
            Route::post('', [AdminStudentController::class, 'store']);
            Route::get('{id}', [AdminStudentController::class, 'show']);
            Route::put('{id}', [AdminStudentController::class, 'update']);
            Route::put('{id}/toggle', [AdminStudentController::class, 'toggle']);
            Route::delete('{id}', [AdminStudentController::class, 'destroy']);
        });
    });

    /* -------------------------------
       Super Admin — Audit Logs (read-only)
    --------------------------------*/
    Route::prefix('admin/audit-logs')
        ->middleware(['auth:api', 'super_admin'])
        ->group(function () {
            Route::get('/export', [AuditLogController::class, 'export']);
            Route::get('/{id}', [AuditLogController::class, 'show']);
            Route::get('/', [AuditLogController::class, 'index']);
        });


    Route::prefix('school')->name('school.')->middleware('auth:api')->group(function () {

        // School dashboard (any school-admin)
        Route::get('/dashboard', [\App\Http\Controllers\School\V01\DashboardController::class, 'index']);

        // My Profile (any school user)
        Route::get('/profile', [\App\Http\Controllers\School\V01\SchoolProfileController::class, 'show']);
        Route::put('/profile', [\App\Http\Controllers\School\V01\SchoolProfileController::class, 'update']);

        // School Subscription & Invoices (school-admin)
        Route::get('/subscription', [\App\Http\Controllers\School\V01\SchoolSubscriptionController::class, 'index']);
        Route::get('/invoices/{id}', [\App\Http\Controllers\School\V01\SchoolSubscriptionController::class, 'showInvoice']);
        Route::get('/invoices/{id}/pdf', [\App\Http\Controllers\School\V01\SchoolSubscriptionController::class, 'downloadInvoicePdf']);

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
            Route::get('/students', [SchoolStudentController::class, 'index']);
            Route::post('/students', [SchoolStudentController::class, 'store']);
            Route::get('/students/{student}', [SchoolStudentController::class, 'show']);
            Route::put('/students/{student}', [SchoolStudentController::class, 'update']);
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
