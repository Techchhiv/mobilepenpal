<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class StudentExerciseAttemptSeeder extends Seeder
{
    public function run(): void
    {
        $studentId = 1;

        DB::transaction(function () use ($studentId) {
            $now = now();

            DB::table('student_exercise_attempts')
                ->where('student_id', $studentId)
                ->delete();

            DB::table('student_stage_progress')
                ->where('student_id', $studentId)
                ->delete();

            DB::table('student_level_progress')
                ->where('student_id', $studentId)
                ->delete();

            DB::table('student_world_progress')
                ->where('student_id', $studentId)
                ->delete();

            $worldRows = DB::table('worlds')
                ->select('id')
                ->get()
                ->map(fn($w) => [
                    'student_id' => $studentId,
                    'world_id'   => $w->id,
                    'total_stars_earned' => 0,
                    'completion_percentage' => 0,
                    'is_completed' => false,
                    'is_unlocked'  => true,
                    'created_at' => $now,
                    'updated_at' => $now,
                ])
                ->all();

            if (!empty($worldRows)) {
                DB::table('student_world_progress')->insert($worldRows);
            }

            $levelRows = DB::table('levels')
                ->select('id')
                ->get()
                ->map(fn($l) => [
                    'student_id' => $studentId,
                    'level_id'   => $l->id,
                    'total_stars' => 0,
                    'is_completed' => false,
                    'is_unlocked'  => true,
                    'created_at' => $now,
                    'updated_at' => $now,
                ])
                ->all();

            if (!empty($levelRows)) {
                DB::table('student_level_progress')->insert($levelRows);
            }

            $stageRows = DB::table('stages')
                ->select('id')
                ->get()
                ->map(fn($s) => [
                    'student_id'  => $studentId,
                    'stage_id'    => $s->id,
                    'stars_earned' => 0,
                    'status'      => 'unlocked',
                    'created_at'  => $now,
                    'updated_at'  => $now,
                ])
                ->all();

            if (!empty($stageRows)) {
                DB::table('student_stage_progress')->insert($stageRows);
            }

            $exerciseIds = DB::table('stage_exercises')
                ->distinct()
                ->pluck('exercise_id');

            $attemptRows = $exerciseIds->map(fn($exerciseId) => [
                'student_id'  => $studentId,
                'exercise_id' => $exerciseId,
                'user_answer' => null,
                'stroke'      => null,
                'label'       => null,
                'is_correct'  => false,
                'created_at'  => $now,
                'updated_at'  => $now,
            ])->all();

            foreach (array_chunk($attemptRows, 1000) as $chunk) {
                DB::table('student_exercise_attempts')->insert($chunk);
            }
        });
    }
}
