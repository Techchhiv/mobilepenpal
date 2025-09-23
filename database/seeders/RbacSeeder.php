<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;
use App\Models\User;

class RbacSeeder extends Seeder
{
    public function run(): void
    {
        app(\Spatie\Permission\PermissionRegistrar::class)->forgetCachedPermissions();

        // ----------------------------
        // Define all permissions
        // ----------------------------
        $perms = [
            // Console
            'console.view',

            // User / Role / Permission management
            'users.manage','roles.manage','permissions.manage',

            // ----------------------------
            // New requirements
            // ----------------------------

            // User Management
            'users.view','users.create','users.update','users.delete','users.enable_disable','users.assign_children',

            // School Management
            'schools.view','schools.create','schools.update','schools.delete','schools.enable_disable',

            // Branch Management
            'branches.view','branches.create','branches.update','branches.delete','branches.enable_disable',

            // School Admin Accounts
            'school_admins.view','school_admins.create','school_admins.update','school_admins.delete',
            'school_admins.enable_disable','school_admins.reassign_school','school_admins.reset_password',

            // Support View / Dashboard
            'support.dashboard.view',

            // HQ Summary
            'hq.summary.view',

            // Teacher Management
            'teachers.view','teachers.create','teachers.update','teachers.delete','teachers.enable_disable','teachers.assign_branch',

            // Parent Management
            'parents.view','parents.create','parents.update','parents.delete','parents.enable_disable','parents.create_children',

            // Children & Enrollment
            'children.view','children.create','children.update','children.delete',
            'enrollments.create','enrollments.update','enrollments.disable',

            // Classroom Management
            'classrooms.view','classrooms.create','classrooms.update','classrooms.delete','classrooms.enable_disable',

            // School Dashboard
            'school.dashboard.view',
        ];

        // ----------------------------
        // Create Permissions
        // ----------------------------
        foreach ($perms as $name) {
            Permission::findOrCreate($name, 'api');
        }

        // ----------------------------
        // Create Roles
        // ----------------------------
        $super  = Role::firstOrCreate(['name' => 'super-admin',  'guard_name' => 'api']);
        $school = Role::firstOrCreate(['name' => 'school-admin', 'guard_name' => 'api']);
        $cust   = Role::firstOrCreate(['name' => 'customer',     'guard_name' => 'api']);

        // ----------------------------
        // Assign Permissions
        // ----------------------------

        // Super Admin → everything
        $super->syncPermissions(Permission::all());

        // School Admin → restricted set
        $schoolAdminPerms = [
            'teachers.view','teachers.create','teachers.update','teachers.delete','teachers.enable_disable','teachers.assign_branch',
            'parents.view','parents.create','parents.update','parents.delete','parents.enable_disable','parents.create_children',
            'children.view','children.create','children.update',
            'enrollments.create','enrollments.update','enrollments.disable',
            'classrooms.view','classrooms.create','classrooms.update','classrooms.delete','classrooms.enable_disable',
            'school.dashboard.view',
        ];
        $school->syncPermissions(Permission::whereIn('name', $schoolAdminPerms)->get());

        // Customer → no management perms
        $cust->syncPermissions([]);

        // ----------------------------
        // Seed default Super Admin User
        // ----------------------------
        $name  = env('ADMIN_NAME', 'admin');
        $email = env('ADMIN_EMAIL', 'admin@gmail.com');
        $pass  = env('ADMIN_PASSWORD', 'admin12345');

        $user = User::updateOrCreate(
            ['email' => $email],
            ['name' => $name, 'password' => Hash::make($pass), 'email_verified_at' => now()]
        );

        $user->syncRoles(['super-admin']); // guard already matches

        $this->command->info("✅ Seeded Super Admin: {$email} / {$pass}");
    }
}
