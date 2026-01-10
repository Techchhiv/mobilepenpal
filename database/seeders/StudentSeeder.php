<?php
namespace Database\Seeders;

use App\Models\Student;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;

class StudentSeeder extends Seeder
{
    public function run(): void
    {
        $studentData = [
            'school_id' => 1,
            'school_key' => 'GHS2024',
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
            'mode' => 'student',
            'is_active' => true,
        ];

        $existingStudent = Student::where('email', $studentData['email'])
            ->orWhere('phone', $studentData['phone'])
            ->first();

        if ($existingStudent) {
            return;
        }

        Student::create([
            'school_id' => $studentData['school_id'],
            'school_key' => $studentData['school_key'],
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
            'mode' => $studentData['mode'],
            'is_active' => $studentData['is_active'],
        ]);
    }
}
