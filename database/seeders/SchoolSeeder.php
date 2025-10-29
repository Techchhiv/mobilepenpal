<?php

namespace Database\Seeders;

use App\Models\School;
use Illuminate\Database\Seeder;

class SchoolSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {

        $schools = [
            [
                'name' => 'Greenwood High School',
                'slug' => 'greenwood-high-school',
                'school_key' => 'GHS2024',
                'admin_email' => 'admin@greenwood.edu',
                'is_active' => true,
            ],
            [
                'name' => 'Riverside Academy',
                'slug' => 'riverside-academy',
                'school_key' => 'RIV2024',
                'admin_email' => 'principal@riverside.edu',
                'is_active' => true,
            ],
            [
                'name' => 'Mountain View Elementary',
                'slug' => 'mountain-view-elementary',
                'school_key' => 'MVE2024',
                'admin_email' => 'info@mountainview.edu',
                'is_active' => true,
            ],
        ];

        foreach ($schools as $schoolData) {
            School::updateOrCreate(
                ['slug' => $schoolData['slug']],
                $schoolData
            );
        }
    }
}
