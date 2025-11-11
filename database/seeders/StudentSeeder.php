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
            'first_name' => 'David',
            'last_name' => 'San',
            'nickname' => 'David',
            'age' => 15,
            'gender' => 'male',
            'date_of_birth' => '2008-05-15',
            'parent_first_name' => 'David',
            'parent_last_name' => 'San',
            'email' => 'techchiv@gmail.com',
            'phone' => '069558076',
            'password' => 'password123',
            'address' => 'Phnom Penh, Cambodia',
            'enrollment_year' => '2024',
            'mode' => 'student',
            'level' => 1,
            'streak' => 0,
            'time_spent' => 0,
            'is_active' => true,
        ];

        $existingStudent = Student::where('email', $studentData['email'])
            ->orWhere('phone', $studentData['phone'])
            ->first();

        if ($existingStudent) {
            Log::info("Student with email {$studentData['email']} or phone {$studentData['phone']} already exists.");
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
            'level' => $studentData['level'],
            'streak' => $studentData['streak'],
            'time_spent' => $studentData['time_spent'],
            'is_active' => $studentData['is_active'],
        ]);
    }
}
