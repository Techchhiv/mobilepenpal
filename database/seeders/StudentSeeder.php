<?php
namespace Database\Seeders;

use App\Models\School;
use App\Models\Student;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;

class StudentSeeder extends Seeder
{
    public function run(): void
    {
        $itcSchool = School::where('school_key', 'SCH-QI8AJ1')->first();
        $itcSchoolId = $itcSchool ? $itcSchool->id : 1;

        $students = [
            [
                // 'school_id' => 1,
                // 'school_key' => 'GHS2024',
                'first_name' => 'Julian',
                'last_name' => 'Thorne',
                'nickname' => 'Julian',
                'age' => 15,
                'gender' => 'male',
                'date_of_birth' => '2008-05-15',
                'parent_first_name' => 'Amara',
                'parent_last_name' => 'Vance',
                'email' => 'amara@gmail.com',
                'phone' => '069558076',
                'password' => 'password123',
                'address' => 'Phnom Penh, Cambodia',
                'enrollment_year' => '2024',
                // 'mode' => 'student',
                'is_active' => true,
                'coin' => 1000,
            ],
            [
                'school_id' => $itcSchoolId,
                'school_key' => 'SCH-QI8AJ1',
                'first_name' => 'Sok',
                'last_name' => 'Chea',
                'nickname' => 'Sok',
                'age' => 15,
                'gender' => 'male',
                'date_of_birth' => '2008-08-20',
                'parent_first_name' => 'Minea',
                'parent_last_name' => 'Chea',
                'email' => 'sok.chea@itc.edu.kh',
                'phone' => '012345678',
                'password' => 'password123',
                'address' => 'Phnom Penh, Cambodia',
                'enrollment_year' => '2024',
                // 'mode' => 'student',
                'is_active' => true,
            ],
        ];

        foreach ($students as $studentData) {
            $existingStudent = Student::where('email', $studentData['email'])
                ->orWhere('phone', $studentData['phone'])
                ->first();

            if ($existingStudent) {
                continue;
            }

            Student::create([
                'school_id' => $studentData['school_id'] ?? null,
                'school_key' => $studentData['school_key'] ?? null,
                'first_name' => $studentData['first_name'],
                'last_name' => $studentData['last_name'],
                'nickname' => $studentData['nickname'],
                'age' => $studentData['age'],
                'gender' => $studentData['gender'],
                'date_of_birth' => $studentData['date_of_birth'],
                'parent_first_name' => $studentData['parent_first_name'],
                'parent_last_name' => $studentData['parent_last_name'],
                'email' => $studentData['email'],
                'phone' => $studentData['phone'],
                'password' => Hash::make($studentData['password']),
                'address' => $studentData['address'],
                'enrollment_year' => $studentData['enrollment_year'],
                // 'mode' => $studentData['mode'] ?? 'student',
                'is_active' => $studentData['is_active'],
                'coin' => $studentData['coin'] ?? 0,
                'xp' => $studentData['xp'] ?? 0,
                'streak' => $studentData['streak'] ?? 0,
                'unlocked_avatars' => $studentData['unlocked_avatars'] ?? [],
            ]);
        }
    }
}
