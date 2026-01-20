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

    /**
     * ✅ School-scoped (tenant) roles may ONLY receive these permissions.
     * NOTE: Curriculum/world management is ADMIN-ONLY, so it is NOT included here.
     */
    private array $schoolPermWhitelist = [
        'teachers.view','teachers.create','teachers.update','teachers.delete','teachers.enable_disable',
        'student.view','student.create','student.update','student.delete','student.enable_disable',
        'parents.view','parents.create','parents.update','parents.delete','parents.enable_disable','parents.create_children',
        'children.view','children.create','children.update','children.delete',
        'enrollments.view','enrollments.create','enrollments.update','enrollments.disable',
        'classrooms.view','classrooms.create','classrooms.update','classrooms.delete','classrooms.enable_disable',
        'school.dashboard.view',
    ];

    public function run(): void
    {
        // 0) Clear Spatie cache
        app(\Spatie\Permission\PermissionRegistrar::class)->forgetCachedPermissions();

        // 1) Seed GLOBAL permissions
        foreach ($this->allPermissions() as $name) {
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

    /** Small helper to generate standard CRUD + enable/disable permissions */
    private function crud(string $prefix): array
    {
        return [
            "{$prefix}.view",
            "{$prefix}.create",
            "{$prefix}.update",
            "{$prefix}.delete",
            "{$prefix}.enable_disable",
        ];
    }

    /** Global permission catalog (single source of truth) */
    private function allPermissions(): array
    {
        $perms = [];

        // Console / Core mgmt
        $perms[] = 'console.view';
        $perms = array_merge($perms, [
            'users.manage', 'roles.manage', 'permissions.manage',
            'manage_clients.manage', 'payments.manage', 'analytics.manage', 'reports.manage',
        ]);

        // CRUD resources
        $perms = array_merge($perms, $this->crud('roles'));
        $perms = array_merge($perms, $this->crud('permissions'));
        $perms = array_merge($perms, $this->crud('manage_clients'));
        $perms = array_merge($perms, $this->crud('payments'));
        $perms = array_merge($perms, $this->crud('analytics'));
        $perms = array_merge($perms, $this->crud('reports'));
        $perms = array_merge($perms, $this->crud('users'));
        $perms = array_merge($perms, $this->crud('schools'));
        $perms = array_merge($perms, $this->crud('branches'));
        $perms = array_merge($perms, $this->crud('school_admins'));
        $perms = array_merge($perms, $this->crud('teachers'));
        $perms = array_merge($perms, $this->crud('parents'));
        $perms = array_merge($perms, $this->crud('children'));
        $perms = array_merge($perms, $this->crud('student'));
        $perms = array_merge($perms, $this->crud('classrooms'));

        // Special-case (your existing schema)
        $perms = array_merge($perms, [
            'teachers.assign_branch',
            'parents.create_children',

            'enrollments.view','enrollments.create','enrollments.update','enrollments.disable',

            'school_admins.reassign_school',
            'school_admins.reset_password',

            'support.dashboard.view',
            'hq.summary.view',

            'school.dashboard.view',
        ]);

        // ✅ Curriculum / World management (ADMIN-ONLY)
        // (We seed these permissions globally, but DO NOT whitelist them for school roles.)
        $perms = array_merge($perms, $this->crud('worlds'));
        $perms = array_merge($perms, $this->crud('levels'));
        $perms = array_merge($perms, $this->crud('stages'));
        $perms = array_merge($perms, $this->crud('exercises'));
        $perms = array_merge($perms, $this->crud('stage_exercises'));

        // Menus
        $perms = array_merge($perms, [
            'menu.manage_clients',
            'menu.payments',
            'menu.analytics',
            'menu.reports',
            // Optional if your frontend wants it; safe to seed even if unused:
            'menu.curriculum',
        ]);

        // unique & reindex
        $perms = array_values(array_unique($perms));
        sort($perms);

        return $perms;
    }

    /** Create/update a role and sync its permissions (by names or collection) */
    private function upsertRole(string $name, $permissions, ?int $schoolId = null): Role
    {
        $role = Role::firstOrCreate([
            'name'       => $name,
            'guard_name' => self::GUARD,
            'school_id'  => $schoolId, // null = global
        ]);

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
            // ✅ Super Admin has everything (including curriculum/world management)
            'super-admin' => Permission::all(),

            // NOTE: school-admin role exists globally here, but it does NOT receive curriculum perms.
            // (So "school users" can't manage worlds/levels/stages/exercises.)
            'school-admin' => [
                ...$this->crud('teachers'),
                ...$this->crud('student'),
                ...$this->crud('parents'),
                ...$this->crud('children'),
                'enrollments.view','enrollments.create','enrollments.update','enrollments.disable',
                ...$this->crud('classrooms'),
                'school.dashboard.view',

                // admin tools (as you had)
                'users.manage','roles.manage','permissions.manage',
            ],

            'payment-manager' => [
                ...$this->crud('payments'),
                'menu.payments',
            ],

            'teacher' => [
                ...$this->crud('teachers'),
            ],

            'student' => [
                ...$this->crud('student'),
            ],

            'client-manager' => [
                ...$this->crud('manage_clients'),
                'menu.manage_clients',
            ],

            'user-manager' => [
                'users.manage','roles.manage','permissions.manage',
                ...$this->crud('users'),
                ...$this->crud('roles'),
                ...$this->crud('permissions'),
            ],

            'enrollments-manager' => [
                'enrollments.view','enrollments.create','enrollments.update','enrollments.disable',
                'school.dashboard.view',
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

        // Tenant role blueprints (MUST be whitelisted by $schoolPermWhitelist)
        $blueprints = [
            'teacher-manager' => [
                'teachers.view','teachers.create','teachers.update','teachers.delete','teachers.enable_disable',
                'classrooms.view','classrooms.create','classrooms.update','classrooms.delete','classrooms.enable_disable',
                'school.dashboard.view',
            ],
            'student-manager' => [
                'student.view','student.create','student.update','student.delete','student.enable_disable',
                'children.view','children.create','children.update','children.delete',
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
