<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;
use App\Models\User;
use App\Models\School;

class RbacSeeder extends Seeder
{
    /** Guard used by Spatie Permission */
    private const GUARD = 'api';

    /** Safe permissions a school-scoped (tenant) role may receive */
    private array $schoolPermWhitelist = [
        'teachers.view','teachers.create','teachers.update','teachers.delete','teachers.enable_disable',
        'student.view','student.create','student.update','student.delete','student.enable_disable',
        'parents.view','parents.create','parents.update','parents.delete','parents.enable_disable','parents.create_children',
        'children.view','children.create','children.update',
        'enrollments.view','enrollments.create','enrollments.update','enrollments.disable',
        'classrooms.view','classrooms.create','classrooms.update','classrooms.delete','classrooms.enable_disable',
        'school.dashboard.view',
    ];

    /** Global permission catalog */
    private array $allPermissions = [
        // Console / Core mgmt
        'console.view',
        'users.manage', 'roles.manage', 'permissions.manage',
        'manage_clients.manage', 'payments.manage', 'analytics.manage', 'reports.manage',

        // Roles / Permissions CRUD
        'roles.view','roles.create','roles.update','roles.delete','roles.enable_disable',
        'permissions.view','permissions.create','permissions.update','permissions.delete','permissions.enable_disable',

        // Clients
        'manage_clients.view','manage_clients.create','manage_clients.update','manage_clients.delete','manage_clients.enable_disable',

        // Payments
        'payments.view','payments.create','payments.update','payments.delete','payments.enable_disable',

        // Analytics
        'analytics.view','analytics.create','analytics.update','analytics.delete','analytics.enable_disable',

        // Reports
        'reports.view','reports.create','reports.update','reports.delete','reports.enable_disable',

        // Users
        'users.view','users.create','users.update','users.delete','users.enable_disable',

        // Orgs
        'schools.view','schools.create','schools.update','schools.delete','schools.enable_disable',
        'branches.view','branches.create','branches.update','branches.delete','branches.enable_disable',

        // School admins
        'school_admins.view','school_admins.create','school_admins.update','school_admins.delete','school_admins.enable_disable',
        'school_admins.reassign_school','school_admins.reset_password',

        // Dashboards / HQ
        'support.dashboard.view','hq.summary.view',

        // Teachers
        'teachers.view','teachers.create','teachers.update','teachers.delete','teachers.enable_disable','teachers.assign_branch',

        // Parents / Children
        'parents.view','parents.create','parents.update','parents.delete','parents.enable_disable','parents.create_children',
        'children.view','children.create','children.update','children.delete',

        // Enrollments
        'enrollments.view','enrollments.create','enrollments.update','enrollments.disable',

        // Classrooms
        'classrooms.view','classrooms.create','classrooms.update','classrooms.delete','classrooms.enable_disable',

        // School dashboard
        'school.dashboard.view',

        // Menus
        'menu.manage_clients','menu.payments','menu.analytics','menu.reports',
    ];

    public function run(): void
    {
        // 0) Clear Spatie cache
        app(\Spatie\Permission\PermissionRegistrar::class)->forgetCachedPermissions();

        // 1) Seed GLOBAL permissions
        foreach ($this->allPermissions as $name) {
            Permission::findOrCreate($name, self::GUARD);
        }

        // 2) Seed GLOBAL roles
        $this->seedGlobalRoles();

        // 3) Seed Super Admin user
        $this->seedSuperAdminUser();

        // 4) Seed TENANT roles per school (if schools table exists)
        if (Schema::hasTable('schools')) {
            $this->seedPerSchoolDefaultRoles();
        }

        $this->command->info('✅ RBAC seeding completed.');
    }

    /** Create/update a role and sync its permissions (by names or collection) */
    private function upsertRole(string $name, $permissions, ?int $schoolId = null): Role
    {
        $role = Role::firstOrCreate([
            'name'       => $name,
            'guard_name' => self::GUARD,
            'school_id'  => $schoolId, // null = global
        ]);

        // Accept either a Permission Collection or array of names
        if (is_array($permissions)) {
            $permissions = Permission::whereIn('name', $permissions)->get();
        }
        $role->syncPermissions($permissions);
        return $role;
    }

    /** Seed global roles (no school_id) */
    private function seedGlobalRoles(): void
    {
        $map = [
            'super-admin' => Permission::all(),

            'school-admin' => [
                'teachers.view','teachers.create','teachers.update','teachers.delete','teachers.enable_disable',
                'student.view','student.create','student.update','student.delete','student.enable_disable',
                'parents.view','parents.create','parents.update','parents.delete','parents.enable_disable','parents.create_children',
                'children.view','children.create','children.update',
                'enrollments.view','enrollments.create','enrollments.update','enrollments.disable',
                'classrooms.view','classrooms.create','classrooms.update','classrooms.delete','classrooms.enable_disable',
                'school.dashboard.view',
                'users.manage','roles.manage','permissions.manage',
            ],

            'payment-manager' => [
                'payments.view','payments.create','payments.update','payments.delete','payments.enable_disable','menu.payments'
            ],

            'teacher' => [
                'teachers.view','teachers.create','teachers.update','teachers.delete','teachers.enable_disable',
            ],

            'student' => [
                'student.view','student.create','student.update','student.delete','student.enable_disable',
            ],

            'client-manager' => [
                'manage_clients.view','manage_clients.create','manage_clients.update','manage_clients.delete','manage_clients.enable_disable','menu.manage_clients'
            ],

            'user-manager' => [
                'users.manage','roles.manage','permissions.manage',
                'users.view','users.create','users.update','users.delete',
                'roles.view','roles.create','roles.update','roles.delete',
                'permissions.view','permissions.create','permissions.update','permissions.delete',
            ],

            // Optional global: enrollments-manager
            'enrollments-manager' => [
                'enrollments.view','enrollments.create','enrollments.update','enrollments.disable','school.dashboard.view',
            ],
        ];

        foreach ($map as $roleName => $perms) {
            $this->upsertRole($roleName, $perms, null);
        }

        $this->command->info('✅ Global roles seeded.');
    }

    /** Create the Super Admin user from .env */
    private function seedSuperAdminUser(): void
    {
        $user = User::updateOrCreate(
            ['email' => env('ADMIN_EMAIL', 'admin@gmail.com')],
            [
                'name'              => env('ADMIN_NAME', 'admin'),
                'password'          => Hash::make(env('ADMIN_PASSWORD', 'admin12345')),
                'email_verified_at' => now(),
            ]
        );

        $user->syncRoles(['super-admin']);
        $this->command->info("✅ Super Admin ready: {$user->email}");
    }

    /** Seed per-school (tenant) roles for every school */
    private function seedPerSchoolDefaultRoles(): void
    {
        $schools = School::query()->select('id','name')->get();
        if ($schools->isEmpty()) {
            $this->command->warn('ℹ️ No schools found — skipping tenant roles.');
            return;
        }

        $blueprints = [
            'teacher-manager' => [
                'teachers.view','teachers.create','teachers.update','teachers.delete','teachers.enable_disable',
                'classrooms.view','classrooms.create','classrooms.update','classrooms.delete','classrooms.enable_disable',
                'school.dashboard.view',
            ],
            'student-manager' => [
                'parents.view','parents.create','parents.update','parents.delete','parents.enable_disable','parents.create_children',
                'children.view','children.create','children.update',
                'enrollments.view','enrollments.create','enrollments.update','enrollments.disable',
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

        foreach ($schools as $school) {
            foreach ($blueprints as $roleName => $permNames) {
                // Safety net: only allow whitelisted permissions
                $safe = array_values(array_intersect($permNames, $this->schoolPermWhitelist));
                $this->upsertRole($roleName, $safe, $school->id);
            }
        }

        $this->command->info('✅ Tenant roles seeded for all schools.');
    }
}
