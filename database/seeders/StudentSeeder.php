<?php

namespace Database\Seeders;

use App\Models\School;
use App\Models\Student;
use App\Models\StudentDailyStat;
use App\Models\Subscription;
use Carbon\Carbon;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class StudentSeeder extends Seeder
{
    public function run(): void
    {
        $itcSchool = School::where('school_key', 'SCH-QI8AJ1')->first();
        $itcSchoolId = $itcSchool ? $itcSchool->id : 1;
        $accountStart = Carbon::today()->subWeek()->startOfDay();

        $students = [
            [
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
                'is_active' => true,
                'coin' => 1000,
            ],
        ];

        foreach ($students as $studentData) {
            $student = Student::query()
                ->where('email', $studentData['email'])
                ->orWhere('phone', $studentData['phone'])
                ->first() ?? new Student();

            $student->fill([
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
                'is_active' => $studentData['is_active'],
                'coin' => $studentData['coin'] ?? 0,
                'xp' => $studentData['xp'] ?? 0,
                'streak' => 0,
                'unlocked_avatars' => $studentData['unlocked_avatars'] ?? [],
                'created_at' => $accountStart->copy(),
                'updated_at' => now(),
            ]);
            $student->save();

            if ($student->first_name === 'Julian') {
                $end = Carbon::yesterday();
                $start = $end->copy()->subMonth();
                Subscription::updateOrCreate(
                    [
                        'student_id' => $student->id,
                    ],
                    [
                        'plan' => 'monthly',
                        'amount' => 5.0,
                        'start_date' => $start,
                        'end_date' => $end,
                        'active' => true,
                    ]
                );
            }

            $this->seedDailyStreak(
                student: $student,
                startDate: $accountStart->copy(),
            );
        }
    }

    private function seedDailyStreak(Student $student, Carbon $startDate): void
    {
        StudentDailyStat::where('student_id', $student->id)->delete();

        $lastSeedDate = Carbon::yesterday()->startOfDay();
        $streakDays = $startDate->diffInDays($lastSeedDate) + 1;

        for ($day = 0; $day < $streakDays; $day++) {
            $date = $startDate->copy()->addDays($day);
            $exercisesAttempted = 8 + $day;
            $correctAttempts = max($exercisesAttempted - 1, 1);

            StudentDailyStat::create([
                'student_id' => $student->id,
                'date' => $date->toDateString(),
                'exercises_attempted' => $exercisesAttempted,
                'correct_attempts' => $correctAttempts,
                'incorrect_attempts' => $exercisesAttempted - $correctAttempts,
                'stages_completed' => 1,
                'stars_earned' => 2,
                'time_spent_seconds' => 600 + ($day * 45),
                'created_at' => $date->copy()->setTime(8, 0),
                'updated_at' => $date->copy()->setTime(8, 15),
            ]);
        }

        $student->streak = $streakDays;
        $student->updated_at = now();
        $student->save();
    }
}
