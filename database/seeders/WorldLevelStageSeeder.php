<?php
// database/seeders/WorldLevelStageSeeder.php
namespace Database\Seeders;

use App\Models\World;
use App\Models\Level;
use App\Models\Stage;
use App\Models\Student;
use App\Models\StudentLevelProgress;
use App\Models\StudentStageProgress;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Log;

class WorldLevelStageSeeder extends Seeder
{
    public function run(): void
    {
        // Create World 1: រៀនអក្សរ (Learning Letters)
        $khmerMathWorld = World::create([
            'name' => 'រៀនអក្សរ',
            'description' => 'រៀនអក្សរតាមព្យុជ្ជនៈខ្មែរ',
            'is_completed' => false,
            'is_active' => true,
        ]);

        // Create 10 Levels for Khmer Letters World
        $levelsKhmerMath = [];
        for ($i = 1; $i <= 10; $i++) {
            $levelsKhmerMath[] = Level::create([
                'world_id' => $khmerMathWorld->id,
                'name' => 'Level ' . $i,
                'order_index' => $i,
                'required_stars' => $i * 3,
            ]);
        }

        // Create Stages for Khmer Letters World
        $stageCount = 0;
        foreach ($levelsKhmerMath as $level) {
            $stagesPerLevel = $level->order_index === 3 ? 8 : 6;

            for ($j = 1; $j <= $stagesPerLevel; $j++) {
                Stage::create([
                    'level_id' => $level->id,
                    'name' => 'Stage ' . (++$stageCount),
                    'order_index' => $j,
                    'max_stars' => 3,
                ]);
            }
        }

        // Create World 2: រៀនលេខ (Learning Numbers)
        $numbersWorld = World::create([
            'name' => 'រៀនលេខ',
            'description' => 'ការអនុវត្តន៍លំហាត់គណិត',
            'is_completed' => false,
            'is_active' => true,
        ]);

        // Create 10 Levels for Numbers World
        $levelsNumbers = [];
        for ($i = 1; $i <= 10; $i++) {
            $levelsNumbers[] = Level::create([
                'world_id' => $numbersWorld->id,
                'name' => 'Level ' . $i,
                'order_index' => $i,
                'required_stars' => $i * 3,
            ]);
        }

        // Create Stages for Numbers World
        $stageCount = 0;
        foreach ($levelsNumbers as $level) {
            $stagesPerLevel = 5;

            for ($j = 1; $j <= $stagesPerLevel; $j++) {
                Stage::create([
                    'level_id' => $level->id,
                    'name' => 'Stage ' . (++$stageCount),
                    'order_index' => $j,
                    'max_stars' => 3,
                ]);
            }
        }

        $student = Student::find(1);
        if ($student) {
            $this->createStudentProgress($student, $levelsKhmerMath[0], 9, 20, false);

            $this->createCompletedWorldProgress($student, $levelsNumbers, $numbersWorld);

        }
    }

    private function createStudentProgress($student, $level, $completedStages, $totalStages, $isLevelCompleted = false): void
    {
        // Create level progress using direct model
        StudentLevelProgress::create([
            'student_id' => $student->id,
            'level_id' => $level->id,
            'total_stars' => $completedStages * 3,
            'is_completed' => $isLevelCompleted,
            'unlocked' => true,
            'last_played' => now(),
        ]);

        $stages = $level->stages()->orderBy('order_index')->get();

        // Create completed stages
        for ($i = 0; $i < min($completedStages, count($stages)); $i++) {
            StudentStageProgress::create([
                'student_id' => $student->id,
                'stage_id' => $stages[$i]->id,
                'stars_earned' => 3, // Max stars for completed stages
                'completion_rate' => 100.0,
                'status' => 'completed',
                'last_played' => now(),
            ]);
        }

        // Create current stage (in progress)
        if ($completedStages < count($stages) && !$isLevelCompleted) {
            StudentStageProgress::create([
                'student_id' => $student->id,
                'stage_id' => $stages[$completedStages]->id,
                'stars_earned' => 0,
                'completion_rate' => 0.0,
                'status' => 'in_progress',
                'last_played' => now(),
            ]);
        }

        // Create locked stages
        for ($i = $completedStages + 1; $i < count($stages); $i++) {
            StudentStageProgress::create([
                'student_id' => $student->id,
                'stage_id' => $stages[$i]->id,
                'stars_earned' => 0,
                'completion_rate' => 0.0,
                'status' => 'locked',
                'last_played' => null,
            ]);
        }
    }

    private function createCompletedWorldProgress($student, $levels, $world): void
    {
        $totalStages = $world->stages()->count();
        $totalStars = $totalStages * 3;

        $world->update(['is_completed' => true]);

        foreach ($levels as $level) {
            $levelStages = $level->stages()->orderBy('order_index')->get();

            StudentLevelProgress::create([
                'student_id' => $student->id,
                'level_id' => $level->id,
                'total_stars' => $levelStages->count() * 3,
                'is_completed' => true,
                'unlocked' => true,
                'last_played' => now(),
            ]);

            foreach ($levelStages as $stage) {
                StudentStageProgress::create([
                    'student_id' => $student->id,
                    'stage_id' => $stage->id,
                    'stars_earned' => 3, // Max stars
                    'completion_rate' => 100.0,
                    'status' => 'completed',
                    'last_played' => now(),
                ]);
            }
        }
    }
}
