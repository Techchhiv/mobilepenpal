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
        $progressService = new StudentProgress();

        $progressService->unlockWorldForStudent(Auth::id());

        $worlds = World::withCount([
            'levels',
            'studentLevelProgress as completed_levels_count' => function ($query) {
                $query->where('is_completed', true);
            }
        ])->with('studentProgress')
            ->where('is_active', true)
            ->orderBy('order_index')
            ->get();

        $this->setResult('worlds', WorldIndexResource::collection($worlds));
        return $this->returnResponse();
    }

    public function showWorld($id): JsonResponse
    {
        $world = World::with("levels")->find($id);

        if (!$world) {
            return $this->returnError('World not found', 404);
        }

        $this->setResult('world', new WorldWithLevelResource($world));

        return $this->returnResponse();
    }

    public function showLevel($levelId): JsonResponse
    {
        $studentId = auth()->id();

        $level = Level::with(['stages.studentProgress' => function ($query) use ($studentId) {
            $query->where('student_id', $studentId);
        }])->find($levelId);

        if (!$level) {
            return $this->returnError('Level not found', 404);
        }

        $this->setResult('level', new LevelWithStageResource($level));

        return $this->returnResponse();
    }

    public function showStage($stageId): JsonResponse
    {
        $stage = Stage::with('exercises')->find($stageId);

        if (!$stage) {
            return $this->returnError('Stage not found', 404);
        }

        $this->setResult('stage', new StageWithExercisesResource($stage));
        return $this->returnResponse();
    }

    public function submitExerciseBatch(Request $request): JsonResponse
    {
        $student = auth('students')->user();
        if (!$student) return $this->returnError('User not authenticated', 401);

        $studentId = $student->id;
        $classroomId = $student->current_classroom_id ?? null;

        if ($classroomId) {
            $isEnrolled = ClassroomEnrollment::where('classroom_id', $classroomId)
                ->where('student_id', $studentId)
                ->where('status', 'enrolled')
                ->exists();

            if (!$isEnrolled) {
                return $this->returnError('You are not enrolled in this classroom.', 403);
            }

            $active = Classroom::whereKey($classroomId)->where('is_active', true)->exists();
            if (!$active) {
                return $this->returnError('This classroom is inactive.', 422);
            }
        }

        $attempts = $request->input('attempts', []);
        if (empty($attempts)) {
            return $this->returnError('No attempts provided', 400);
        }

        $durationSeconds = (int) $request->input('duration_seconds', 0);

        $summary = [];
        $progressService = new StudentProgress();

        DB::transaction(function () use ($studentId, $classroomId, $attempts, $progressService, $durationSeconds, &$summary) {
            $firstAttempt = collect($attempts)->first();

            if (!is_array($firstAttempt) || !isset($firstAttempt['exercise_id'])) {
                throw new \InvalidArgumentException('Invalid attempts payload: missing exercise_id');
            }

            $exerciseId = $firstAttempt['exercise_id'];

            $stageId = StageExercise::where('exercise_id', $exerciseId)
                ->orderBy('stage_id') // deterministic
                ->value('stage_id');

            $totalExercises = 0;
            $correctAttempts = 0;

            foreach ($attempts as $attempt) {
                StudentExerciseAttempt::create([
                    'student_id'   => $studentId,
                    'classroom_id' => $classroomId, // ✅ INJECT HERE
                    'exercise_id'  => $attempt['exercise_id'],
                    'user_answer'  => $attempt['user_answer'] ?? null,
                    'is_correct'   => $attempt['is_correct'],
                    'stroke'       => $attempt['stroke'] ?? null,
                    'label'        => $attempt['label'] ?? null,
                ]);

                $totalExercises++;
                if (!empty($attempt['is_correct'])) $correctAttempts++;
            }

            if ($durationSeconds > 0 && $stageId) {
                StudentSession::create([
                    'student_id'       => $studentId,
                    'classroom_id'     => $classroomId,
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
                date: Carbon::today(),
                classroomId: $classroomId,
            );

            $results = [
                'total_exercises'  => $totalExercises,
                'correct_attempts' => $correctAttempts,
                'stage_id'         => $stageId,
            ];

            $progressResult = $progressService->updateStageProgress(
                $studentId,
                $stageId,
                $results,
                $classroomId
            );

            $summary = [
                'stars_earned'     => $progressResult['stars_earned'],
                'correct_answers'  => $progressResult['correct_attempts'],
                'total_questions'  => $progressResult['total_exercises'],
                'is_new_best'      => $progressResult['is_new_best'] ?? false,
                'next_stage_id'    => $progressResult['next_stage_id'] ?? null,
            ];
        });

        $this->setResult('summary', $summary);
        return $this->returnResponse();
    }
}
