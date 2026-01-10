<?php

namespace Database\Seeders;

use App\Models\School;
use App\Models\Branch;
use App\Models\Teacher;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class SchoolSeeder extends Seeder
{
    public function run()
    {
        $schools = [
            [
                'name' => 'Greenwood High School',
                'slug' => 'greenwood-high-school',
                'school_key' => 'GHS2024',
                'admin_email' => 'admin@greenwood.edu',
                'is_active' => true,
                'branches' => [
                    [
                        'branch_name' => 'Greenwood Main Campus',
                        'branch_code' => 'GHS-MAIN',
                        'city' => 'Phnom Penh',
                        'province' => 'Phnom Penh',
                        'phone' => '012345678',
                        'contact_email' => 'main@greenwood.edu',
                        'is_active' => true,
                        'teachers' => [
                            [
                                'name' => 'Sok Dara',
                                'email' => 'dara.main@greenwood.edu',
                                'phone' => '010111222',
                                'subject' => 'Khmer',
                            ],
                            [
                                'name' => 'Chan Sreyneang',
                                'email' => 'sreyneang.main@greenwood.edu',
                                'phone' => '010333444',
                                'subject' => 'Math',
                            ],
                        ],
                    ],
                    [
                        'branch_name' => 'Greenwood West Campus',
                        'branch_code' => 'GHS-WEST',
                        'city' => 'Siem Reap',
                        'province' => 'Siem Reap',
                        'phone' => '098765432',
                        'contact_email' => 'west@greenwood.edu',
                        'is_active' => true,
                        'teachers' => [
                            [
                                'name' => 'Heng Vuthy',
                                'email' => 'vuthy.west@greenwood.edu',
                                'phone' => '011555666',
                                'subject' => 'English',
                            ],
                            [
                                'name' => 'Ly Sopheak',
                                'email' => 'sopheak.west@greenwood.edu',
                                'phone' => '011777888',
                                'subject' => 'Science',
                            ],
                        ],
                    ],
                ],
            ],
            [
                'name' => 'Riverside Academy',
                'slug' => 'riverside-academy',
                'school_key' => 'RIV2024',
                'admin_email' => 'principal@riverside.edu',
                'is_active' => true,
                'branches' => [
                    [
                        'branch_name' => 'Riverside Downtown',
                        'branch_code' => 'RIV-DT',
                        'city' => 'Phnom Penh',
                        'province' => 'Phnom Penh',
                        'contact_email' => 'downtown@riverside.edu',
                        'is_active' => true,
                        'teachers' => [
                            [
                                'name' => 'Kim Rina',
                                'email' => 'rina.dt@riverside.edu',
                                'phone' => '012000111',
                                'subject' => 'Khmer',
                            ],
                            [
                                'name' => 'Touch Makara',
                                'email' => 'makara.dt@riverside.edu',
                                'phone' => '012000222',
                                'subject' => 'History',
                            ],
                        ],
                    ],
                    [
                        'branch_name' => 'Riverside North',
                        'branch_code' => 'RIV-NORTH',
                        'city' => 'Kandal',
                        'province' => 'Kandal',
                        'contact_email' => 'north@riverside.edu',
                        'is_active' => true,
                        'teachers' => [
                            [
                                'name' => 'Nou Sothida',
                                'email' => 'sothida.north@riverside.edu',
                                'phone' => '012000333',
                                'subject' => 'Math',
                            ],
                            [
                                'name' => 'Chea Piseth',
                                'email' => 'piseth.north@riverside.edu',
                                'phone' => '012000444',
                                'subject' => 'Science',
                            ],
                        ],
                    ],
                ],
            ],
            [
                'name' => 'Mountain View Elementary',
                'slug' => 'mountain-view-elementary',
                'school_key' => 'MVE2024',
                'admin_email' => 'info@mountainview.edu',
                'is_active' => true,
                'branches' => [
                    [
                        'branch_name' => 'Mountain View Main',
                        'branch_code' => 'MVE-MAIN',
                        'city' => 'Battambang',
                        'province' => 'Battambang',
                        'is_active' => true,
                        'teachers' => [
                            [
                                'name' => 'Phan Sovan',
                                'email' => 'sovan.main@mountainview.edu',
                                'phone' => '015111222',
                                'subject' => 'Khmer',
                            ],
                            [
                                'name' => 'Kong Sophy',
                                'email' => 'sophy.main@mountainview.edu',
                                'phone' => '015333444',
                                'subject' => 'Art',
                            ],
                        ],
                    ],
                    [
                        'branch_name' => 'Mountain View East',
                        'branch_code' => 'MVE-EAST',
                        'city' => 'Pursat',
                        'province' => 'Pursat',
                        'is_active' => true,
                        'teachers' => [
                            [
                                'name' => 'Samnang Vicheka',
                                'email' => 'vicheka.east@mountainview.edu',
                                'phone' => '015555666',
                                'subject' => 'English',
                            ],
                            [
                                'name' => 'Ouk Sothea',
                                'email' => 'sothea.east@mountainview.edu',
                                'phone' => '015777888',
                                'subject' => 'Math',
                            ],
                        ],
                    ],
                ],
            ],
        ];

        foreach ($schools as $schoolData) {
            $branches = $schoolData['branches'];
            unset($schoolData['branches']);

            $school = School::updateOrCreate(
                ['slug' => $schoolData['slug']],
                $schoolData
            );

            foreach ($branches as $branchData) {
                $teachers = $branchData['teachers'] ?? [];
                unset($branchData['teachers']);

                $branch = Branch::updateOrCreate(
                    ['branch_code' => $branchData['branch_code']],
                    array_merge($branchData, [
                        'school_id' => $school->id,
                        'is_active' => true,
                    ])
                );

                // Create 2+ teachers per branch
                foreach ($teachers as $i => $teacherData) {
                    $generatedTeacherId = $branch->branch_code . '-T' . str_pad((string)($i + 1), 3, '0', STR_PAD_LEFT);

                    Teacher::updateOrCreate(
                        ['email' => $teacherData['email']],
                        [
                            // 'branch_id' => $branch->id,
                            'school_id' => $school->id,
                            'school_key' => $school->school_key,
                            'teacher_id' => $generatedTeacherId,
                            'name' => $teacherData['name'],
                            'email' => $teacherData['email'],
                            // 'password' => Hash::make('password123'),
                            'phone' => $teacherData['phone'] ?? null,
                            'subject' => $teacherData['subject'] ?? null,
                            'photo' => $teacherData['photo'] ?? null,
                            'is_active' => true,
                        ]
                    );
                }
            }
        }
    }
}
