<?php

namespace App\Http\Controllers\Student\V01;

use App\Helpers\ClassroomJoinCode;
use App\Http\Resources\Student\V01\Classroom\ClassroomDetailResource;
use App\Http\Resources\Student\V01\Classroom\ClassroomResource;
use App\Models\Classroom;
use App\Models\ClassroomEnrollment;
use App\Models\Student;
use App\Models\StudentExerciseAttempt;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ClassroomController extends Controller
{
    public function index()
    {
        /** @var Student|null $student */
        $student = auth('students')->user();

        if (!$student) {
            return $this->returnError(__('messages.user_not_authenticated'), 401);
        }

        $enrollments = ClassroomEnrollment::where('student_id', $student->id)
            ->where('status', 'enrolled')
            ->with([
                'classroom' => function ($q) {
                    $q->select('id', 'teacher_id', 'name', 'is_active', 'join_code')
                        ->with(['teacher:id,name'])
                        ->withCount([
                            'enrollments as students_count' => function ($q) {
                                $q->where('status', 'enrolled');
                            }
                        ]);
                }
            ])
            ->orderByDesc('enrolled_at')
            ->get();

        $classrooms = $enrollments
            ->filter(fn($e) => $e->classroom)
            ->map(function ($e) {
                $e->classroom->setRelation('enrollment', $e);
                return $e->classroom;
            })
            ->values();

        $this->setResult(
            'classrooms',
            ClassroomResource::collection($classrooms)
        );

        return $this->returnResponse();
    }

    public function show(Classroom $classroom)
    {
        /** @var Student|null $student */
        $student = auth('students')->user();

        if (!$student) {
            return $this->returnError(__('messages.user_not_authenticated'), 401);
        }

        $enrollment = ClassroomEnrollment::where('classroom_id', $classroom->id)
            ->where('student_id', $student->id)
            ->where('status', 'enrolled')
            ->first();

        if (!$enrollment) {
            return $this->returnError(__('messages.unauthorized'), 403);
        }

        $classroom->load([
            'teacher:id,name',
        ])->loadCount([
            'enrollments as students_count' => function ($q) {
                $q->where('status', 'enrolled');
            }
        ]);

        $students = ClassroomEnrollment::where('classroom_id', $classroom->id)
            ->where('status', 'enrolled')
            ->with('student:id,first_name,last_name,nickname,avatar')
            ->orderByDesc('enrolled_at')
            ->get()
            ->pluck('student')
            ->filter()
            ->values();

        // Calculate student's progress stats for this classroom
        $totalAttempts = StudentExerciseAttempt::where('student_id', $student->id)->count();
        $correctAttempts = StudentExerciseAttempt::where('student_id', $student->id)->where('is_correct', true)->count();
        $accuracy = $totalAttempts > 0 ? round(($correctAttempts / $totalAttempts) * 100) : 0;
        $starsEarned = $correctAttempts;

        $myStats = [
            'total_attempts' => $totalAttempts,
            'correct_attempts' => $correctAttempts,
            'accuracy' => $accuracy,
            'stars_earned' => $starsEarned,
        ];

        $classroom->setRelation('enrollment', $enrollment);
        $classroom->setRelation('classmates', $students);
        $classroom->setAttribute('my_stats', $myStats);

        $this->setResult('classroom', new ClassroomDetailResource($classroom));
        return $this->returnResponse();
    }

    /**
     * Join classroom via Join Code
     */
    public function joinByCode(Request $request)
    {
        /** @var Student|null $student */
        $student = auth('students')->user();

        if (!$student) {
            return $this->returnError(__('messages.user_not_authenticated'), 401);
        }

        $rawCode = trim((string) ($request->input('join_code') ?? $request->input('code')));
        if (empty($rawCode)) {
            return $this->returnError(__('messages.classroom_join_code_required'), 422);
        }

        $upperCode = strtoupper($rawCode);
        $noDashCode = str_replace('-', '', $upperCode);

        $classroom = Classroom::where('join_code', $upperCode)
            ->orWhere('join_code', $rawCode)
            ->orWhereRaw("UPPER(REPLACE(join_code, '-', '')) = ?", [$noDashCode])
            ->first();

        if (!$classroom) {
            return $this->returnError(__('messages.invalid_join_code'), 404);
        }

        if (!$classroom->is_active) {
            return $this->returnError(__('messages.classroom_inactive'), 400);
        }

        $enrollment = ClassroomEnrollment::where('classroom_id', $classroom->id)
            ->where('student_id', $student->id)
            ->first();

        if ($enrollment) {
            if ($enrollment->status !== 'enrolled') {
                $enrollment->update([
                    'status' => 'enrolled',
                    'enrolled_at' => now(),
                    'left_at' => null,
                ]);
            }
        } else {
            ClassroomEnrollment::create([
                'classroom_id' => $classroom->id,
                'student_id' => $student->id,
                'status' => 'enrolled',
                'enrolled_at' => now(),
            ]);
        }

        // Associate student with the school if not set
        if (!$student->school_id) {
            $student->update(['school_id' => $classroom->school_id]);
        }

        $classroom->load([
            'teacher:id,name',
        ])->loadCount([
            'enrollments as students_count' => function ($q) {
                $q->where('status', 'enrolled');
            }
        ]);

        $this->setMessage(__('messages.joined_classroom_success'));
        $this->setResult('classroom', new ClassroomResource($classroom));
        return $this->returnResponse();
    }
}
