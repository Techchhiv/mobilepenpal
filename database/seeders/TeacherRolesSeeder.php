<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;

class TeacherRolesSeeder extends Seeder
{
    private const GUARD = 'teachers';

    private array $roleNamesToDuplicate = [
        'teacher',
    ];

    public function run(): void
    {
        app(\Spatie\Permission\PermissionRegistrar::class)->forgetCachedPermissions();

        $apiPermissions = Permission::where('guard_name', 'api')->get();

        foreach ($apiPermissions as $p) {
            Permission::firstOrCreate([
                'name' => $p->name,
                'guard_name' => self::GUARD,
            ]);
        }

        $apiRoles = Role::where('guard_name', 'api')
            ->whereNull('school_id')
            ->whereIn('name', $this->roleNamesToDuplicate)
            ->get();

        foreach ($apiRoles as $apiRole) {
            $teacherRole = Role::firstOrCreate([
                'name'       => $apiRole->name,
                'guard_name' => self::GUARD,
                'school_id'  => null,
            ]);

            $permNames = $apiRole->permissions->pluck('name')->toArray();
            $teacherPerms = Permission::where('guard_name', self::GUARD)
                ->whereIn('name', $permNames)
                ->get();

            $teacherRole->syncPermissions($teacherPerms);
        }
    }
}
