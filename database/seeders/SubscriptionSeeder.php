<?php

namespace Database\Seeders;

use App\Models\School;
use App\Models\Student;
use App\Models\Subscription;
use Carbon\Carbon;
use Illuminate\Database\Seeder;

class SubscriptionSeeder extends Seeder
{
    public function run(): void
    {
        $now = Carbon::now();

        $school = School::where('school_key', 'SCH-QI8AJ1')->first();

        if ($school) {
            Subscription::updateOrCreate(
                ['school_id' => $school->id, 'plan' => 'yearly'],
                [
                    'student_id' => null,
                    'amount' => 99.99,
                    'start_date' => $now->toDateString(),
                    'end_date' => $now->copy()->addYear()->toDateString(),
                    'active' => true,
                ]
            );
        }

        $julian = Student::where('nickname', 'Julian')->whereNull('school_id')->first();

        if ($julian) {
            Subscription::updateOrCreate(
                ['student_id' => $julian->id, 'plan' => 'yearly'],
                [
                    'school_id' => null,
                    'amount' => 49.99,
                    'start_date' => $now->toDateString(),
                    'end_date' => $now->copy()->addYear()->toDateString(),
                    'active' => true,
                ]
            );
        }
    }
}
