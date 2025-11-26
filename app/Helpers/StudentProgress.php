<?php

namespace App\Helpers;

use App\Http\Resources\Student\V01\World\WorldIndexResource;
use App\Models\Level;
use App\Models\Stage;
use App\Models\StudentLevelProgress;
use App\Models\StudentStageProgress;
use App\Models\StudentWorldProgress;
use App\Models\World;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class StudentProgress
{
    public function getWorldsWithProgress($studentId = null)
    {
        $studentId = $studentId ?? Auth::id();

        $this->unlockWorldForStudent($studentId);

        $worlds = World::withCount([
            'levels',
            'studentLevelProgress as completed_levels_count' => function ($query)  {
                $query->where('is_completed', true);
            }
        ])
            ->with('studentProgress')
            ->where('is_active', true)
            ->orderBy('order_index')
            ->get();

        return WorldIndexResource::collection($worlds);
    }

    public function updateStageProgress($studentId, $stageId, $results)
    {
        return DB::transaction(function () use ($studentId, $stageId, $results) {
            $stage = Stage::with(['level.world'])->find($stageId);
            if (!$stage) return null;

            $totalExercises = $results['total_exercises'];
            $correctAttempts = $results['correct_attempts'];
            $score = $totalExercises > 0 ? round(($correctAttempts / $totalExercises) * 100) : 0;
            $newStarsEarned = $this->calculateStarsEarned($score, $stage->max_stars);

            $stageProgress = StudentStageProgress::where('student_id', $studentId)
                ->where('stage_id', $stageId)
                ->first();

            $currentStars = $stageProgress->stars_earned ?? 0;

            if ($newStarsEarned > $currentStars) {
                $stageProgress = StudentStageProgress::updateOrCreate(
                    ['student_id' => $studentId, 'stage_id' => $stageId],
                    [
                        'stars_earned' => $newStarsEarned,
                        'status' => 'completed',
                    ]
                );
                $stageProgress->refresh();
            }

            $this->checkAndUnlockNextContent($studentId, $stage);

            return [
                'stars_earned' => $newStarsEarned,
                'correct_attempts' => $correctAttempts,
                'total_exercises' => $totalExercises,
            ];
        });
    }

    private function calculateStarsEarned($score, $maxStars)
    {
        if ($score == 100) return $maxStars;
        if ($score >= 50) return 2;
        return 1;
    }

    private function checkAndUnlockNextContent($studentId, $stage)
    {
        $level = $stage->level;
        $world = $level->world;

        $levelStages = $level->stages;
        $completedStages = StudentStageProgress::where('student_id', $studentId)
            ->whereIn('stage_id', $levelStages->pluck('id'))
            ->where('status', 'completed')
            ->count();

        if ($completedStages === $levelStages->count()) {
            $this->completeLevel($studentId, $level);
            $this->checkWorldCompletion($studentId, $world);
        } else {
            $this->unlockNextStage($studentId, $stage);
        }
    }

    private function completeLevel($studentId, $level)
    {
        $totalStars = StudentStageProgress::where('student_id', $studentId)
            ->whereIn('stage_id', $level->stages->pluck('id'))
            ->sum('stars_earned');

        StudentLevelProgress::updateOrCreate(
            ['student_id' => $studentId, 'level_id' => $level->id],
            [
                'is_completed' => true,
                'is_unlocked' => true,
                'total_stars' => $totalStars,
            ]
        );

        $this->unlockNextLevel($studentId, $level);
    }

    private function unlockNextLevel($studentId, $currentLevel)
    {
        $nextLevel = Level::where('world_id', $currentLevel->world_id)
            ->where('order_index', '>', $currentLevel->order_index)
            ->orderBy('order_index')
            ->first();

        if ($nextLevel) {
            StudentLevelProgress::updateOrCreate(
                ['student_id' => $studentId, 'level_id' => $nextLevel->id],
                ['is_unlocked' => true, 'is_completed' => false, 'total_stars' => 0]
            );

            $firstStage = $nextLevel->stages()->orderBy('order_index')->first();
            if ($firstStage) {
                StudentStageProgress::updateOrCreate(
                    ['student_id' => $studentId, 'stage_id' => $firstStage->id],
                    ['status' => 'unlocked', 'stars_earned' => 0]
                );
            }
        }
    }

    private function checkWorldCompletion($studentId, $world)
    {
        $worldLevels = $world->levels;
        $completedLevels = StudentLevelProgress::where('student_id', $studentId)
            ->whereIn('level_id', $worldLevels->pluck('id'))
            ->where('is_completed', true)
            ->count();

        if ($completedLevels === $worldLevels->count()) {
            $totalStars = StudentLevelProgress::where('student_id', $studentId) // ← FIXED: 'student_id'
                ->whereIn('level_id', $worldLevels->pluck('id'))
                ->sum('total_stars');

            StudentWorldProgress::updateOrCreate(
                ['student_id' => $studentId, 'world_id' => $world->id],
                [
                    'is_completed' => true,
                    'completion_percentage' => 100,
                    'total_stars_earned' => $totalStars,
                ]
            );

            $this->unlockNextWorld($studentId, $world);
        } else {
            $completionPercentage = round(($completedLevels / $worldLevels->count()) * 100);
            StudentWorldProgress::where('student_id', $studentId)
                ->where('world_id', $world->id)
                ->update(['completion_percentage' => $completionPercentage]);
        }
    }

    private function unlockNextWorld($studentId, $currentWorld)
    {
        $nextWorld = World::where('order_index', '>', $currentWorld->order_index)
            ->where('is_active', true)
            ->orderBy('order_index')
            ->first();

        if ($nextWorld) {
            $this->initializeWorldProgress($studentId, $nextWorld->id);
        }
    }

    private function unlockNextStage($studentId, $currentStage)
    {
        $nextStage = Stage::where('level_id', $currentStage->level_id)
            ->where('order_index', '>', $currentStage->order_index)
            ->orderBy('order_index')
            ->first();

        if ($nextStage) {
            StudentStageProgress::updateOrCreate(
                ['student_id' => $studentId, 'stage_id' => $nextStage->id],
                ['status' => 'unlocked', 'stars_earned' => 0]
            );
        }
    }

    public function unlockWorldForStudent($studentId)
    {
        $firstWorld = World::where('is_active', true)
            ->orderBy('order_index')
            ->first();

        if ($firstWorld) {
            $hasFirstWorldProgress = StudentWorldProgress::where('student_id', $studentId)
                ->where('world_id', $firstWorld->id)
                ->exists();

            if (!$hasFirstWorldProgress) {
                $this->initializeWorldProgress($studentId, $firstWorld->id);
            } else {
                StudentWorldProgress::where('student_id', $studentId)
                    ->where('world_id', $firstWorld->id)
                    ->update(['is_unlocked' => true]);
            }
        }

        $defaultWorlds = World::where('is_active', true)
            ->where('is_unlocked_by_default', true)
            ->where('id', '!=', $firstWorld->id)
            ->get();

        foreach ($defaultWorlds as $world) {
            $hasProgress = StudentWorldProgress::where('student_id', $studentId)
                ->where('world_id', $world->id)
                ->exists();

            if (!$hasProgress) {
                $this->initializeWorldProgress($studentId, $world->id);
            }
        }

        return true;
    }

    public function initializeWorldProgress($studentId, $worldId)
    {
        return DB::transaction(function () use ($studentId, $worldId) {
            $world = World::where('is_active', true)->find($worldId);

            if (!$world) {
                return false;
            }

            StudentWorldProgress::updateOrCreate(
                [
                    'student_id' => $studentId,
                    'world_id' => $worldId,
                ],
                [
                    'is_unlocked' => true,
                    'is_completed' => false,
                    'completion_percentage' => 0,
                    'total_stars_earned' => 0,
                ]
            );

            $firstLevel = Level::where('world_id', $worldId)
                ->orderBy('order_index')
                ->first();

            if ($firstLevel) {
                StudentLevelProgress::updateOrCreate(
                    [
                        'student_id' => $studentId,
                        'level_id' => $firstLevel->id,
                    ],
                    [
                        'is_unlocked' => true,
                        'is_completed' => false,
                        'total_stars' => 0,
                    ]
                );

                $firstStage = Stage::where('level_id', $firstLevel->id)
                    ->orderBy('order_index')
                    ->first();

                if ($firstStage) {
                    StudentStageProgress::updateOrCreate(
                        [
                            'student_id' => $studentId,
                            'stage_id' => $firstStage->id,
                        ],
                        [
                            'status' => 'unlocked',
                            'stars_earned' => 0,
                        ]
                    );
                }
            }

            return true;
        });
    }

    public function initializeStudentProgress($studentId)
    {
        $hasWorldProgress = StudentWorldProgress::where('student_id', $studentId)->exists();

        if (!$hasWorldProgress) {
            $firstWorld = World::where('is_active', true)
                ->where('unlocked_by_default', true)
                ->orderBy('order_index')
                ->first();

            if ($firstWorld) {
                return $this->initializeWorldProgress($studentId, $firstWorld->id);
            }
        }

        return false;
    }
}
