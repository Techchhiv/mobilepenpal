<?php

namespace Database\Seeders;

use App\Models\School;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class SchoolSeeder extends Seeder
{
    public function run(): void
    {
        $schools = [
            [
                'name' => 'ITC',
                'school_key' => 'SCH-QI8AJ1',
                'admin_email' => 'itc@gmail.com',
                'admin_password' => 'password123',
            ],
            [
                'name' => 'Demo School B',
                'school_key' => 'SCH-DEMO-B',
                'admin_email' => 'b@gmail.com',
                'admin_password' => 'password123',
            ],
        ];

        foreach ($schools as $s) {
            $school = School::updateOrCreate(
                ['school_key' => $s['school_key']],
                [
                    'name' => $s['name'],
                    'slug' => Str::slug($s['name']),
                    'admin_email' => $s['admin_email'],
                    'is_active' => true,
                ]
            );

            $user = User::updateOrCreate(
                ['email' => $s['admin_email']],
                [
                    'name' => $s['name'] . ' Admin',
                    'password' => Hash::make($s['admin_password']),
                    'school_id' => $school->id,
                ]
            );

            if (method_exists($user, 'assignRole')) {
                try {
                    $user->assignRole('school-admin');
                } catch (\Throwable $e) {
                }
            }
        }
    }
}
