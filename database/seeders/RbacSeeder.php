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
        // Clear cached permissions
        app(\Spatie\Permission\PermissionRegistrar::class)->forgetCachedPermissions();

        // ----------------------------
        // 1️⃣ Define all permissions
        // ----------------------------
        $permissions = [
            'console.view',
            'users.manage',
            'roles.manage',
            'permissions.manage',
            'manage_clients.manage',
            'payments.manage',
            'analytics.manage',
            'reports.manage',
            'roles.view',
            'roles.create',
            'roles.update',
            'roles.delete',
            'roles.enable_disable',
            'permissions.view',
            'permissions.create',
            'permissions.update',
            'permissions.delete',
            'permissions.enable_disable',
            'manage_clients.view',
            'manage_clients.create',
            'manage_clients.update',
            'manage_clients.delete',
            'manage_clients.enable_disable',
            'payments.view',
            'payments.create',
            'payments.update',
            'payments.delete',
            'payments.enable_disable',
            'analytics.view',
            'analytics.create',
            'analytics.update',
            'analytics.delete',
            'analytics.enable_disable',
            'reports.view',
            'reports.create',
            'reports.update',
            'reports.delete',
            'reports.enable_disable',
            'users.view',
            'users.create',
            'users.update',
            'users.delete',
            'users.enable_disable',
            'schools.view',
            'schools.create',
            'schools.update',
            'schools.delete',
            'schools.enable_disable',
            'branches.view',
            'branches.create',
            'branches.update',
            'branches.delete',
            'branches.enable_disable',
            'school_admins.view',
            'school_admins.create',
            'school_admins.update',
            'school_admins.delete',
            'school_admins.enable_disable',
            'school_admins.reassign_school',
            'school_admins.reset_password',
            'support.dashboard.view',
            'hq.summary.view',
            'teachers.view',
            'teachers.create',
            'teachers.update',
            'teachers.delete',
            'teachers.enable_disable',
            'teachers.assign_branch',
            'parents.view',
            'parents.create',
            'parents.update',
            'parents.delete',
            'parents.enable_disable',
            'parents.create_children',
            'children.view',
            'children.create',
            'children.update',
            'children.delete',
            'enrollments.create',
            'enrollments.update',
            'enrollments.disable',
            'classrooms.view',
            'classrooms.create',
            'classrooms.update',
            'classrooms.delete',
            'classrooms.enable_disable',
            'school.dashboard.view',
            'menu.manage_clients',
            'menu.payments',
            'menu.analytics',
            'menu.reports',
        ];

        foreach ($permissions as $perm) {
            Permission::findOrCreate($perm, 'api');
        }

        // ----------------------------
        // 2️⃣ Create Roles
        // ----------------------------
        $roles = [
            'super-admin' => Permission::all(),

            'school-admin' => Permission::whereIn('name', [
                'teachers.view',
                'teachers.create',
                'teachers.update',
                'teachers.delete',
                'teachers.enable_disable',
                'parents.view',
                'parents.create',
                'parents.update',
                'parents.delete',
                'parents.enable_disable',
                'parents.create_children',
                'children.view',
                'children.create',
                'children.update',
                'enrollments.create',
                'enrollments.update',
                'enrollments.disable',
                'classrooms.view',
                'classrooms.create',
                'classrooms.update',
                'classrooms.delete',
                'classrooms.enable_disable',
                'school.dashboard.view',
                'users.manage',
                'roles.manage',
                'permissions.manage',
            ])->get(),


            'payment-manager' => Permission::whereIn('name', [
                'payments.view',
                'payments.create',
                'payments.update',
                'payments.delete',
                'payments.enable_disable',
                'menu.payments'
            ])->get(),

            'client-manager' => Permission::whereIn('name', [
                'manage_clients.view',
                'manage_clients.create',
                'manage_clients.update',
                'manage_clients.delete',
                'manage_clients.enable_disable',
                'menu.manage_clients'
            ])->get(),

            // ✅ New User Manager role
            'user-manager' => Permission::whereIn('name', [
                'users.manage',
                'roles.manage',
                'permissions.manage',
                'users.view',
                'users.create',
                'users.update',
                'users.delete',
                'roles.view',
                'roles.create',
                'roles.update',
                'roles.delete',
                'permissions.view',
                'permissions.create',
                'permissions.update',
                'permissions.delete',
            ])->get(),

        ];

        foreach ($roles as $name => $perms) {
            $role = Role::firstOrCreate(['name' => $name, 'guard_name' => 'api']);
            $role->syncPermissions($perms);
        }

        // ----------------------------
        // 3️⃣ Seed default Super Admin User
        // ----------------------------
        $adminName  = env('ADMIN_NAME', 'admin');
        $adminEmail = env('ADMIN_EMAIL', 'admin@gmail.com');
        $adminPass  = env('ADMIN_PASSWORD', 'admin12345');

        $adminUser = User::updateOrCreate(
            ['email' => $adminEmail],
            [
                'name' => $adminName,
                'password' => Hash::make($adminPass),
                'email_verified_at' => now()
            ]
        );
        $adminUser->syncRoles(['super-admin']);

        $this->command->info("✅ Seeded Super Admin: {$adminEmail} / {$adminPass}");
        $this->command->info("✅ User Manager role created successfully");
    }
}
