<?php

namespace App\Helpers;

use App\Http\Resources\Student\V01\World\WorldIndexResource;
use App\Models\Level;
use App\Models\Stage;
use App\Models\StudentDailyStat;
use App\Models\StudentLevelProgress;
use App\Models\StudentStageProgress;
use App\Models\StudentWorldProgress;
use App\Models\World;
use Carbon\Carbon;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class StudentProgress
{
    public function getWorldsWithProgress($studentId = null)
    {
        $studentId = $studentId ?? Auth::id();

        $this->unlockWorldForStudent($studentId);

        $worlds = World::withCount([
            'levels',
            'studentLevelProgress as completed_levels_count' => function ($query) {
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

            $nextStageId = $this->checkAndUnlockNextContent($studentId, $stage);

            return [
                'stars_earned' => $newStarsEarned,
                'correct_attempts' => $correctAttempts,
                'total_exercises' => $totalExercises,
                'next_stage_id' => $nextStageId,
            ];
        });
    }

    private function calculateStarsEarned($score, $maxStars)
    {
        if ($score == 100) return $maxStars;
        if ($score >= 50) return 2;
        if ($score >= 25) return 1;
        return 0;
    }

    private function checkAndUnlockNextContent($studentId, $stage)
    {
        $level = $stage->level;
        $world = $level->world;

        $activeStages = Stage::where('level_id', $level->id)
            ->where('is_active', true)
            ->orderBy('order_index')
            ->get();

        if ($activeStages->isEmpty()) {
            $this->completeLevel($studentId, $level);
            $this->checkWorldCompletion($studentId, $world);
            return null;
        }

        $completedStages = StudentStageProgress::where('student_id', $studentId)
            ->whereIn('stage_id', $activeStages->pluck('id'))
            ->where('status', 'completed')
            ->count();

        $nextActiveStage = Stage::where('level_id', $level->id)
            ->where('is_active', true)
            ->where('order_index', '>', $stage->order_index)
            ->orderBy('order_index')
            ->first();

        if ($completedStages >= $activeStages->count()) {
            $this->completeLevel($studentId, $level);
            $this->checkWorldCompletion($studentId, $world);
            return null;
        }

        if ($nextActiveStage) {
            $progress = StudentStageProgress::firstOrNew([
                'student_id' => $studentId,
                'stage_id'   => $nextActiveStage->id,
            ]);

            if (!$progress->exists) {
                $progress->status = 'unlocked';
                $progress->stars_earned = 0;
                $progress->save();
            } elseif ($progress->status === 'locked') {
                $progress->status = 'unlocked';
                $progress->save();
            }

            return $nextActiveStage->id;
        }

        return $this->unlockNextStage($studentId, $stage);
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
            ->where('is_active', true)
            ->orderBy('order_index')
            ->get()
            ->first(function ($lvl) {
                return $lvl->stages()->where('is_active', true)->exists();
            });

        if (!$nextLevel) {
            return;
        }

        $levelProgress = StudentLevelProgress::firstOrNew([
            'student_id' => $studentId,
            'level_id'   => $nextLevel->id,
        ]);

        $levelProgress->is_unlocked = true;
        if (!$levelProgress->exists) {
            $levelProgress->is_completed = false;
            $levelProgress->total_stars  = 0;
        }
        $levelProgress->save();

        $firstStage = $nextLevel->stages()
            ->where('is_active', true)
            ->orderBy('order_index')
            ->first();

        if ($firstStage) {
            $progress = StudentStageProgress::firstOrNew([
                'student_id' => $studentId,
                'stage_id'   => $firstStage->id,
            ]);

            if (!$progress->exists) {
                $progress->status = 'unlocked';
                $progress->stars_earned = 0;
                $progress->save();
            } elseif ($progress->status === 'locked') {
                $progress->status = 'unlocked';
                $progress->save();
            }
        }
    }


    private function checkWorldCompletion($studentId, $world)
    {
        $worldLevels = Level::where('world_id', $world->id)
            ->where('is_active', true)
            ->orderBy('order_index')
            ->get(['id']);

        $totalRequired = $worldLevels->count();

        if ($totalRequired === 0) {
            StudentWorldProgress::updateOrCreate(
                ['student_id' => $studentId, 'world_id' => $world->id],
                [
                    'is_completed' => false,
                    'completion_percentage' => 0,
                ]
            );
            return;
        }

        $levelIds = $worldLevels->pluck('id');

        $completedLevels = StudentLevelProgress::where('student_id', $studentId)
            ->whereIn('level_id', $levelIds)
            ->where('is_completed', true)
            ->count();

        if ($completedLevels >= $totalRequired) {
            $totalStars = StudentLevelProgress::where('student_id', $studentId)
                ->whereIn('level_id', $levelIds)
                ->sum('total_stars');

            StudentWorldProgress::updateOrCreate(
                ['student_id' => $studentId, 'world_id' => $world->id],
                [
                    'is_completed' => true,
                    'completion_percentage' => 100,
                    'total_stars_earned' => $totalStars,
                    'is_unlocked' => true,
                ]
            );

            $this->unlockNextWorld($studentId, $world);
            return;
        }

        $completionPercentage = (int) round(($completedLevels / $totalRequired) * 100);

        StudentWorldProgress::updateOrCreate(
            ['student_id' => $studentId, 'world_id' => $world->id],
            [
                'is_completed' => false,
                'completion_percentage' => $completionPercentage,
                'is_unlocked' => true,
            ]
        );
    }

    private function unlockNextWorld($studentId, $currentWorld)
    {
        $candidateWorlds = World::where('order_index', '>', $currentWorld->order_index)
            ->where('is_active', true)
            ->orderBy('order_index')
            ->get();

        foreach ($candidateWorlds as $world) {
            $firstActiveLevel = Level::where('world_id', $world->id)
                ->where('is_active', true)
                ->orderBy('order_index')
                ->first();

            if (!$firstActiveLevel) {
                continue;
            }

            $firstActiveStage = Stage::where('level_id', $firstActiveLevel->id)
                ->where('is_active', true)
                ->orderBy('order_index')
                ->first();

            if (!$firstActiveStage) {
                continue;
            }

            $this->initializeWorldProgress($studentId, $world->id);
            return;
        }
    }


    private function unlockNextStage($studentId, $currentStage)
    {
        $nextStage = Stage::where('level_id', $currentStage->level_id)
            ->where('order_index', '>', $currentStage->order_index)
            ->where('is_active', true)
            ->orderBy('order_index')
            ->first();

        if ($nextStage) {
            $progress = StudentStageProgress::firstOrNew([
                'student_id' => $studentId,
                'stage_id'   => $nextStage->id,
            ]);

            if (!$progress->exists) {
                $progress->status = 'unlocked';
                $progress->stars_earned = 0;
                $progress->save();
            } elseif ($progress->status === 'locked') {
                $progress->status = 'unlocked';
                $progress->save();
            }

            return $nextStage->id;
        }

        return null;
    }


    public function unlockWorldForStudent($studentId)
    {
        return DB::transaction(function () use ($studentId) {
            $firstWorld = null;

            $activeWorlds = World::where('is_active', true)
                ->orderBy('order_index')
                ->get();

            foreach ($activeWorlds as $w) {
                $firstLevel = $w->activeLevels()->first();
                if (!$firstLevel) continue;

                $firstStage = Stage::where('level_id', $firstLevel->id)
                    ->where('is_active', true)
                    ->orderBy('order_index')
                    ->first();

                if ($firstStage) {
                    $firstWorld = $w;
                    break;
                }
            }

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

            $this->initializeDefaultUnlockedContent($studentId);

            return true;
        });
    }

    public function initializeWorldProgress($studentId, $worldId)
    {
        $world = World::where('is_active', true)->find($worldId);
        if (!$world) return false;

        $this->ensureWorldUnlocked((int)$studentId, (int)$worldId);

        $firstLevel = Level::where('world_id', $worldId)
            ->where('is_active', true)
            ->whereHas('stages', fn($q) => $q->where('is_active', true))
            ->orderBy('order_index')
            ->first();

        if (!$firstLevel) return true;

        $this->ensureLevelUnlocked((int)$studentId, (int)$firstLevel->id);

        $firstStage = Stage::where('level_id', $firstLevel->id)
            ->where('is_active', true)
            ->orderBy('order_index')
            ->first();

        if ($firstStage) {
            $this->ensureStageUnlocked((int)$studentId, (int)$firstStage->id);
        }

        return true;
    }

    public function initializeStudentProgress($studentId)
    {
        $hasWorldProgress = StudentWorldProgress::where('student_id', $studentId)->exists();

        if (!$hasWorldProgress) {
            $firstWorld = World::where('is_active', true)
                ->where('is_unlocked_by_default', true)
                ->orderBy('order_index')
                ->first();

            if ($firstWorld) {
                return $this->initializeWorldProgress($studentId, $firstWorld->id);
            }
        }

        return false;
    }

    public function addDailyStatsFromSession(
        int $studentId,
        ?int $stageId,
        int $totalExercises,
        int $correctAttempts,
        int $durationSeconds,
        $date = null
    ): void {
        $date = $date
            ? Carbon::parse($date)->toDateString()
            : Carbon::today()->toDateString();

        $incorrectAttempts = max($totalExercises - $correctAttempts, 0);

        $sessionStars   = 0;
        $stageCompleted = false;

        if ($stageId && $totalExercises > 0) {
            $stage = Stage::find($stageId);
            $maxStars = $stage ? (int) $stage->max_stars : 3;

            $score = ($correctAttempts / $totalExercises) * 100;

            $sessionStars = $this->calculateStarsEarned($score, $maxStars);

            if ($score >= 50) {
                $stageCompleted = true;
            }
        }

        /** @var StudentDailyStat $stat */
        $stat = StudentDailyStat::firstOrNew([
            'student_id' => $studentId,
            'date'       => $date,
        ]);

        if (!$stat->exists) {
            $stat->exercises_attempted = 0;
            $stat->correct_attempts    = 0;
            $stat->incorrect_attempts  = 0;
            $stat->stages_completed    = 0;
            $stat->stars_earned        = 0;
            $stat->time_spent_seconds  = 0;
        }

        $stat->exercises_attempted += $totalExercises;
        $stat->correct_attempts    += $correctAttempts;
        $stat->incorrect_attempts  += $incorrectAttempts;
        $stat->stars_earned        += $sessionStars;
        $stat->time_spent_seconds  += $durationSeconds;

        if ($stageCompleted) {
            $stat->stages_completed += 1;
        }

        $stat->save();
    }

    private function initializeDefaultUnlockedContent(int $studentId): void
    {
        $defaultWorlds = World::where('is_active', true)
            ->where('is_unlocked_by_default', true)
            ->orderBy('order_index')
            ->get();

        foreach ($defaultWorlds as $world) {
            $this->ensureWorldUnlocked($studentId, (int)$world->id);


            $this->initializeDefaultUnlockedLevelsAndStages($studentId, $world->id, true);
        }

        $this->initializeDefaultUnlockedLevelsAndStages($studentId, null, false, true);
    }


    private function initializeDefaultUnlockedLevelsAndStages(
        int $studentId,
        ?int $worldId,
        bool $ensureFirstPlayable = false,
        bool $excludeDefaultWorlds = false
    ): void {
        $levelQuery = Level::query()
            ->where('is_active', true)
            ->whereHas('stages', fn($q) => $q->where('is_active', true));

        if ($worldId !== null) {
            $levelQuery->where('world_id', $worldId);
        } elseif ($excludeDefaultWorlds) {
            $levelQuery->whereHas('world', fn($w) => $w->where('is_unlocked_by_default', false));
        }

        $defaultLevels = (clone $levelQuery)
            ->where('is_unlocked_by_default', true)
            ->orderBy('world_id')
            ->orderBy('order_index')
            ->get();

        if ($worldId !== null && $ensureFirstPlayable && $defaultLevels->isEmpty()) {
            $firstPlayable = (clone $levelQuery)
                ->where('world_id', $worldId)
                ->orderBy('order_index')
                ->first();

            if ($firstPlayable) {
                $defaultLevels = collect([$firstPlayable]);
            }
        }

        foreach ($defaultLevels as $level) {
            $this->ensureWorldUnlocked($studentId, (int)$level->world_id);

            $this->ensureLevelUnlocked($studentId, (int)$level->id);

            $defaultStages = Stage::where('level_id', $level->id)
                ->where('is_active', true)
                ->where('is_unlocked_by_default', true)
                ->orderBy('order_index')
                ->get();

            foreach ($defaultStages as $stage) {
                StudentStageProgress::updateOrCreate(
                    ['student_id' => $studentId, 'stage_id' => $stage->id],
                    ['status' => 'unlocked', 'stars_earned' => 0]
                );
            }

            $firstStage = Stage::where('level_id', $level->id)
                ->where('is_active', true)
                ->orderBy('order_index')
                ->first();

            if ($firstStage) {
                $this->ensureStageUnlocked($studentId, (int)$firstStage->id);
            }
        }
    }

    private function ensureWorldUnlocked(int $studentId, int $worldId): void
    {
        StudentWorldProgress::firstOrCreate(
            ['student_id' => $studentId, 'world_id' => $worldId],
            [
                'is_unlocked' => true,
                'is_completed' => false,
                'completion_percentage' => 0,
                'total_stars_earned' => 0,
            ]
        );

        StudentWorldProgress::where('student_id', $studentId)
            ->where('world_id', $worldId)
            ->update(['is_unlocked' => true]);
    }

    private function ensureLevelUnlocked(int $studentId, int $levelId): void
    {
        StudentLevelProgress::firstOrCreate(
            ['student_id' => $studentId, 'level_id' => $levelId],
            [
                'is_unlocked' => true,
                'is_completed' => false,
                'total_stars' => 0,
            ]
        );

        StudentLevelProgress::where('student_id', $studentId)
            ->where('level_id', $levelId)
            ->update(['is_unlocked' => true]);
    }

    private function ensureStageUnlocked(int $studentId, int $stageId): void
    {
        $progress = StudentStageProgress::firstOrCreate(
            ['student_id' => $studentId, 'stage_id' => $stageId],
            [
                'status' => 'unlocked',
                'stars_earned' => 0,
            ]
        );

        if ($progress->status === 'completed') return;

        if ($progress->status === null || $progress->status === 'locked') {
            $progress->status = 'unlocked';
            $progress->save();
        }
    }
}
