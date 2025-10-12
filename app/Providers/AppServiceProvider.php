<?php

namespace App\Providers;

use App\Models\School;
use Illuminate\Support\ServiceProvider;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     *
     * @return void
     */
    public function register()
    {
        //
    }

    /**
     * Bootstrap any application services.
     *
     * @return void
     */
    public function boot(): void
{
    // When a school is created, auto-create its tenant roles
    School::created(function (School $school) {
        $guard = 'api';

        // Define the tenant role blueprints once here
        $blueprints = [
            'teacher-manager' => [
                'teachers.view','teachers.create','teachers.update','teachers.delete','teachers.enable_disable',
                'school.dashboard.view',
            ],
            'student-manager' => [
                'children.view','children.create','children.update',
                'school.dashboard.view',
            ],
            'classroom-manager' => [
                'classrooms.view','classrooms.create','classrooms.update','classrooms.delete','classrooms.enable_disable',
                'school.dashboard.view',
            ],
            'enrollments-manager' => [
                'enrollments.view','enrollments.create','enrollments.update','enrollments.disable',
                'school.dashboard.view',
            ],
        ];

        foreach ($blueprints as $roleName => $permNames) {
            $role = Role::firstOrCreate([
                'name'       => $roleName,
                'guard_name' => $guard,
                'school_id'  => $school->id,
            ]);

            $perms = Permission::whereIn('name', $permNames)->get();
            $role->syncPermissions($perms);
        }

        // make them visible immediately
        app(\Spatie\Permission\PermissionRegistrar::class)->forgetCachedPermissions();
    });
}
}
