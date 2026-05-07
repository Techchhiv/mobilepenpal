<?php

namespace App\Http\Controllers\Student\V01;

use App\Helpers\UploadMedia;
use App\Http\Requests\Student\V01\User\UpdateUserRequest;
use App\Http\Resources\Student\V01\User\UserDetailResource;
use App\Helpers\StudentProgress;
use App\Helpers\StudentSummary;
use App\Models\Classroom;
use App\Models\ClassroomEnrollment;
use App\Models\Student;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpFoundation\JsonResponse;

class UserController extends Controller
{

    public function profile(): JsonResponse
    {
        $authUser = auth::guard('students')->user();

        if (!$authUser) {
            return $this->returnError(__('messages.user_not_authenticated'), 401);
        }

        $studentProgress = new StudentProgress();
        $studentProgress->refreshStudentStreak($authUser->id);

        $this->setResult("profile", new UserDetailResource($authUser));
        $this->setResult(
            "progress",
            $studentProgress->getWorldsWithProgress()
        );
        return $this->returnResponse();
    }

    public function update(UpdateUserRequest $request): JsonResponse
    {
        /** @var Student $student */
        $student = Auth::user();

        if (!$student) {
            return $this->returnError(__('messages.user_not_authenticated'), 401);
        }

        $validated = $request->validated();

        $student->update($validated);

        $this->setResult('students', new UserDetailResource($student));
        return $this->returnResponse();
    }
    public function updatePassword(Request $request): JsonResponse
    {
        $request->validate([
            'current_password' => 'required|string',
            'new_password' => 'required|string|min:6|confirmed',
        ]);

        /** @var Student $student */
        $student = Auth::user();

        if (!Hash::check($request->current_password, $student->password)) {
            return $this->returnError(__('messages.current_password_incorrect'), 422);
        }

        $student->update([
            'password' => Hash::make($request->new_password)
        ]);

        return $this->returnSuccess();
    }

    public function updateParentPin(Request $request): JsonResponse
    {
        $request->validate([
            'parent_pin' => 'required|string|min:4|max:6',
        ]);

        /** @var Student $student */
        $student = Auth::user();

        $student->update([
            'parent_pin' => $request["parent_pin"]
        ]);

        $this->setResult('parent_pin', $request["parent_pin"]);
        return $this->returnResponse();
    }

    public function switchMode(): JsonResponse
    {
        /** @var Student $student */
        $student = Auth::user();

        $newMode = $student["mode"] === 'student' ? 'parent' : 'student';

        $student->update([
            'mode' => $newMode
        ]);

        $this->setResult('mode', $newMode);
        return $this->returnResponse();
    }

    public function checkParentPin(): JsonResponse
    {
        /** @var Student $student */
        $student = Auth::user();

        $isPinSet = !empty($student->parent_pin);

        $this->setResult('is_parent_pin_set', $isPinSet);
        return $this->returnResponse();
    }

    public function updateImage(Request $request): JsonResponse
    {
        $request->validate([
            'image' => 'required|string'
        ]);

        /** @var Student $student */
        $student = Auth::user();

        if (!$student) {
            return $this->returnError(__('messages.user_not_authenticated'), 401);
        }

        if ($student->avatar) {
            $previousPath = public_path($student->avatar);
            if (file_exists($previousPath)) {
                unlink($previousPath);

                $folder = dirname($previousPath);
                while ($folder !== public_path('images') && is_dir($folder) && count(scandir($folder)) === 2) {
                    rmdir($folder);
                    $folder = dirname($folder);
                }
            }
        }

        $imagePath = UploadMedia::uploadImageBase64($request->image);

        if (!$imagePath) {
            return $this->returnError(__('messages.incorrect_image_type'), 422);
        }

        $student->update([
            'avatar' => $imagePath
        ]);

        $this->setResult('student', new UserDetailResource($student));
        return $this->returnResponse();
    }

    public function dailySummary(Request $request): JsonResponse
    {
        /** @var Student|null $student */
        $student = auth::guard('students')->user();

        if (!$student) {
            return $this->returnError(__('messages.user_not_authenticated'), 401);
        }

        $date = $request->query('date', Carbon::now()->toDateString());

        $summary = StudentSummary::getDailySummary($student->id, $date);

        $this->setResult('summary', $summary);
        return $this->returnResponse();
    }

    public function weeklySummary(Request $request): JsonResponse
    {
        /** @var Student|null $student */
        $student = auth::guard('students')->user();

        if (!$student) {
            return $this->returnError(__('messages.user_not_authenticated'), 401);
        }

        $fromDate = $request->query('from_date');
        $toDate = $request->query('to_date');

        if (!$fromDate || !$toDate) {
            $now = Carbon::now();
            $fromDate = $now->copy()->startOfWeek()->toDateString();
            $toDate = $now->copy()->endOfWeek()->toDateString();
        }

        $classroomId = $student->current_classroom_id ? (int) $student->current_classroom_id : null;
        $summary = StudentSummary::getWeeklySummary($student->id, $fromDate, $toDate, $classroomId);

        $this->setResult('summary', $summary);
        return $this->returnResponse();
    }

    public function questSummary(): JsonResponse
    {
        /** @var Student|null $student */
        $student = auth::guard('students')->user();

        if (!$student) {
            return $this->returnError(__('messages.user_not_authenticated'), 401);
        }

        $studentId = $student->id;

        // ── 1. Get stage IDs the student has completed ──
        $completedStageIds = DB::table('student_stage_progress')
            ->where('student_id', $studentId)
            ->where('status', 'completed')
            ->pluck('stage_id');

        // ── 2. Get exercise IDs from those stages, excluding math ──
        $learnedExerciseIds = DB::table('stage_exercises')
            ->whereIn('stage_id', $completedStageIds)
            ->where('is_active', true)
            ->pluck('exercise_id')
            ->unique();

        $learnedExercises = \App\Models\Exercise::query()
            ->whereIn('id', $learnedExerciseIds)
            ->where('character_type', '!=', 'math')
            ->get(['id', 'character', 'character_type']);

        // Unique learned characters
        $allLearnedCharacters = $learnedExercises
            ->pluck('character')
            ->filter()
            ->unique()
            ->values()
            ->all();

        // ── 3. Weakest character (lowest accuracy across ALL attempts for learned exercises) ──
        $weakestCharacters = [];
        if ($learnedExercises->isNotEmpty()) {
            $attempts = DB::table('student_exercise_attempts')
                ->where('student_id', $studentId)
                ->whereIn('exercise_id', $learnedExercises->pluck('id'))
                ->get(['exercise_id', 'is_correct']);

            // Map exercise_id → character
            $exerciseCharMap = $learnedExercises->pluck('character', 'id');

            // Group attempts by character
            $charStats = [];
            foreach ($attempts as $a) {
                $ch = $exerciseCharMap[$a->exercise_id] ?? null;
                if (!$ch)
                    continue;
                if (!isset($charStats[$ch])) {
                    $charStats[$ch] = ['total' => 0, 'correct' => 0];
                }
                $charStats[$ch]['total']++;
                if ($a->is_correct) {
                    $charStats[$ch]['correct']++;
                }
            }

            // Find the weakest (lowest accuracy, minimum 2 attempts)
            $calculatedStats = [];
            foreach ($charStats as $ch => $stat) {
                if ($stat['total'] < 2)
                    continue;
                $acc = $stat['correct'] / $stat['total'];
                $calculatedStats[] = [
                    'character' => $ch,
                    'accuracy' => round($acc, 2),
                    'attempts' => $stat['total'],
                ];
            }

            // Sort by accuracy ascending
            usort($calculatedStats, function ($a, $b) {
                return $a['accuracy'] <=> $b['accuracy'];
            });

            // Take top 5
            $weakestCharacters = array_slice($calculatedStats, 0, 5);
        }

        // ── 4. Recent characters (from the most recently completed level) ──
        $recentCharacters = [];
        $allLevelsCompleted = false;

        // Find the most recently completed stage → its level
        $latestCompletedStage = DB::table('student_stage_progress')
            ->where('student_id', $studentId)
            ->where('status', 'completed')
            ->orderByDesc('updated_at')
            ->first();

        if ($latestCompletedStage) {
            $latestStage = \App\Models\Stage::find($latestCompletedStage->stage_id);
            if ($latestStage) {
                $levelId = $latestStage->level_id;

                // Get all exercises from that level's stages (no math)
                $levelStageIds = DB::table('stages')
                    ->where('level_id', $levelId)
                    ->where('is_active', true)
                    ->pluck('id');

                $recentExerciseIds = DB::table('stage_exercises')
                    ->whereIn('stage_id', $levelStageIds)
                    ->where('is_active', true)
                    ->pluck('exercise_id')
                    ->unique();

                $recentCharacters = \App\Models\Exercise::query()
                    ->whereIn('id', $recentExerciseIds)
                    ->where('character_type', '!=', 'math')
                    ->pluck('character')
                    ->filter()
                    ->unique()
                    ->values()
                    ->all();
            }

            // Check if ALL levels in visible worlds are completed
            $progress = new StudentProgress();
            $visibleWorldIds = $progress->visibleWorldIdsForStudent($studentId);

            $totalLevels = DB::table('levels')
                ->whereIn('world_id', $visibleWorldIds)
                ->where('is_active', true)
                ->count();

            $completedLevels = DB::table('student_level_progress')
                ->where('student_id', $studentId)
                ->where('is_completed', true)
                ->whereIn('level_id', function ($q) use ($visibleWorldIds) {
                    $q->select('id')
                        ->from('levels')
                        ->whereIn('world_id', $visibleWorldIds)
                        ->where('is_active', true);
                })
                ->count();

            $allLevelsCompleted = ($totalLevels > 0 && $completedLevels >= $totalLevels);
        }

        // ── 5. Oldest practiced character (for deep-memory fallback) ──
        $oldestPracticedCharacter = null;
        if (!empty($allLearnedCharacters)) {
            // For each learned character, find when it was last practiced
            $lastPracticedMap = DB::table('student_exercise_attempts as a')
                ->join('exercises as e', 'e.id', '=', 'a.exercise_id')
                ->where('a.student_id', $studentId)
                ->whereIn('e.character', $allLearnedCharacters)
                ->where('e.character_type', '!=', 'math')
                ->groupBy('e.character')
                ->selectRaw('e.character, MAX(a.created_at) as last_practiced')
                ->get()
                ->pluck('last_practiced', 'character');

            // Find the character practiced longest ago
            $oldest = null;
            $oldestDate = null;
            foreach ($lastPracticedMap as $ch => $date) {
                if ($oldestDate === null || $date < $oldestDate) {
                    $oldestDate = $date;
                    $oldest = $ch;
                }
            }

            // Also include characters never practiced (if any)
            $neverPracticed = array_diff($allLearnedCharacters, $lastPracticedMap->keys()->all());
            if (!empty($neverPracticed)) {
                $oldest = reset($neverPracticed);
            }

            if ($oldest) {
                $oldestPracticedCharacter = $oldest;
            }
        }

        $this->setResult('quest_summary', [
            'weakest_characters' => $weakestCharacters,
            'recent_characters' => $recentCharacters,
            'all_learned_characters' => $allLearnedCharacters,
            'oldest_practiced_character' => $oldestPracticedCharacter,
            'all_levels_completed' => $allLevelsCompleted,
        ]);

        return $this->returnResponse();
    }

    public function monthlySummary(Request $request): JsonResponse
    {
        /** @var Student|null $student */
        $student = auth::guard('students')->user();

        if (!$student) {
            return $this->returnError(__('messages.user_not_authenticated'), 401);
        }

        $month = $request->query('month', Carbon::now()->format('Y-m'));

        $summary = StudentSummary::getMonthlySummary($student->id, $month);

        $this->setResult('summary', $summary);
        return $this->returnResponse();
    }
}
