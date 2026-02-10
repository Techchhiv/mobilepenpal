<?php

namespace App\Http\Controllers\Student\V01;

use App\Helpers\StudentProgress;
use App\Http\Resources\Student\V01\World\LevelWithStageResource;
use App\Http\Resources\Student\V01\World\StageWithExercisesResource;
use App\Http\Resources\Student\V01\World\WorldIndexResource;
use App\Http\Resources\Student\V01\World\WorldWithLevelResource;
use App\Models\Classroom;
use App\Models\ClassroomEnrollment;
use App\Models\Exercise;
use App\Models\World;
use App\Models\Level;
use App\Models\Stage;
use App\Models\StageExercise;
use App\Models\StudentExerciseAttempt;
use App\Models\StudentSession;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpFoundation\JsonResponse;

class WorldController extends Controller
{
    public function index()
    {
        $studentId = Auth::id();

        $progressService = new StudentProgress();
        $progressService->unlockWorldForStudent($studentId);

        $worlds = $progressService->visibleWorldQueryForStudent($studentId)
            ->with('studentProgress')
            ->withCount([
                'levels as levels_count' => fn($q) => $q->where('is_active', true),
                'studentLevelProgress as completed_levels_count' => function ($q) {
                    $q->where('is_completed', true)
                        ->whereHas('level', fn($levelQ) => $levelQ->where('is_active', true));
                },
            ])
            ->get();

        $this->setResult('worlds', WorldIndexResource::collection($worlds));
        return $this->returnResponse();
    }

    public function showWorld($id): JsonResponse
    {
        $studentId = auth()->id();
        $progress = new StudentProgress();

        $world = $progress->visibleWorldQueryForStudent($studentId)
            ->where('worlds.id', (int) $id)
            ->with(['levels' => fn($q) => $q->where('is_active', true)->orderBy('order_index')])
            ->first();

        if (!$world) return $this->returnError('World not found', 404);

        $this->setResult('world', new WorldWithLevelResource($world));
        return $this->returnResponse();
    }

    public function showLevel($levelId): JsonResponse
    {
        $studentId = auth()->id();
        $progress = new StudentProgress();
        $visibleWorldIds = $progress->visibleWorldIdsForStudent($studentId);

        $level = Level::query()
            ->where('is_active', true)
            ->whereHas('world', fn($q) => $q->whereIn('worlds.id', $visibleWorldIds))
            ->with([
                'stages' => fn($q) => $q->where('is_active', true)->orderBy('order_index'),
                'stages.studentProgress' => fn($q) => $q->where('student_id', $studentId),
            ])
            ->find($levelId);

        if (!$level) return $this->returnError('Level not found', 404);

        $this->setResult('level', new LevelWithStageResource($level));
        return $this->returnResponse();
    }


    public function showStage($stageId): JsonResponse
    {
        $studentId = auth()->id();
        $progress = new StudentProgress();
        $visibleWorldIds = $progress->visibleWorldIdsForStudent($studentId);

        $stage = Stage::query()
            ->where('is_active', true)
            ->whereHas('level.world', fn($q) => $q->whereIn('worlds.id', $visibleWorldIds)->where('worlds.is_active', true))
            ->with('exercises')
            ->find($stageId);

        if (!$stage) return $this->returnError('Stage not found', 404);

        $this->setResult('stage', new StageWithExercisesResource($stage));
        return $this->returnResponse();
    }


    public function submitExerciseBatch(Request $request): JsonResponse
    {
        $studentId = auth()->id();
        $attempts = $request->input('attempts', []);

        if (empty($attempts)) {
            return $this->returnError('No attempts provided', 400);
        }

        $stageId = (int) $request->input('stage_id', 0);
        if ($stageId <= 0) {
            return $this->returnError('Missing stage_id', 422);
        }

        $progress = new StudentProgress();
        $visibleWorldIds = $progress->visibleWorldIdsForStudent($studentId);

        $allowedStage = Stage::query()
            ->whereKey($stageId)
            ->where('is_active', true)
            ->whereHas('level.world', fn($q) => $q->whereIn('worlds.id', $visibleWorldIds)->where('worlds.is_active', true))
            ->exists();

        if (!$allowedStage) {
            return $this->returnError('Stage not found', 404);
        }

        $durationSeconds = (int) $request->input('duration_seconds', 0);

        $summary = [];
        $progressService = new StudentProgress();

        DB::transaction(function () use ($studentId, $attempts, $progressService, $durationSeconds, $stageId, &$summary) {
            $firstAttempt = collect($attempts)->first();
            if (!is_array($firstAttempt) || !isset($firstAttempt['exercise_id'])) {
                throw new \InvalidArgumentException('Invalid attempts payload: missing exercise_id');
            }

            $exerciseIds = collect($attempts)
                ->pluck('exercise_id')
                ->map(fn($v) => (int) $v)
                ->unique()
                ->values();

            $mappedCount = StageExercise::query()
                ->where('stage_id', $stageId)
                ->where('is_active', true)
                ->whereIn('exercise_id', $exerciseIds)
                ->count();

            if ($mappedCount !== $exerciseIds->count()) {
                throw new \InvalidArgumentException('One or more exercises do not belong to this stage');
            }

            $totalExercises = 0;
            $correctAttempts = 0;

            foreach ($attempts as $attempt) {
                StudentExerciseAttempt::create([
                    'student_id' => $studentId,
                    'exercise_id' => (int) $attempt['exercise_id'],
                    'user_answer' => $attempt['user_answer'] ?? null,
                    'is_correct' => !empty($attempt['is_correct']),
                    'stroke' => $attempt['stroke'] ?? null,
                    'label' => $attempt['label'] ?? null,
                    'math_op' => $attempt['math_op'] ?? null,
                ]);

                $totalExercises++;
                if (!empty($attempt['is_correct'])) {
                    $correctAttempts++;
                }
            }

            if ($durationSeconds > 0) {
                StudentSession::create([
                    'student_id'       => $studentId,
                    'stage_id'         => $stageId,
                    'duration_seconds' => $durationSeconds,
                    'started_at'       => now()->subSeconds($durationSeconds),
                    'ended_at'         => now(),
                ]);
            }

            $progressService->addDailyStatsFromSession(
                studentId: $studentId,
                stageId: $stageId,
                totalExercises: $totalExercises,
                correctAttempts: $correctAttempts,
                durationSeconds: $durationSeconds,
                date: Carbon::today()
            );

            $results = [
                'total_exercises'  => $totalExercises,
                'correct_attempts' => $correctAttempts,
                'stage_id'         => $stageId,
            ];

            $progressResult = $progressService->updateStageProgress($studentId, $stageId, $results);

            $summary = [
                'stars_earned'     => $progressResult['stars_earned'] ?? 0,
                'correct_answers'  => $progressResult['correct_attempts'] ?? 0,
                'total_questions'  => $progressResult['total_exercises'] ?? 0,
                'is_new_best'      => $progressResult['is_new_best'] ?? false,
                'next_stage_id'    => $progressResult['next_stage_id'] ?? null,
            ];
        });

        $this->setResult('summary', $summary);
        return $this->returnResponse();
    }
}
