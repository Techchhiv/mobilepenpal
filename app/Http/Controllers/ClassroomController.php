<?php

namespace App\Http\Controllers;

use App\Helpers\ClassroomJoinCode;
use App\Helpers\StudentSummary;
use App\Http\Controllers\Student\V01\Controller;
use App\Http\Requests\Teacher\V01\StoreClassroomRequest;
use App\Http\Requests\Teacher\V01\UpdateClassroomRequest;
use App\Models\Classroom;
use App\Models\ClassroomEnrollment;
use App\Models\School;
use App\Models\Student;
use App\Models\Teacher;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class ClassroomController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();

        $teacher = Teacher::where('school_id', $user->school_id)
            ->whereRaw('LOWER(email) = ?', [strtolower(trim((string) $user->email))])
            ->first();

        $query = Classroom::query()
            ->where('school_id', $user->school_id)
            ->with(['teacher'])
            ->withCount([
                'enrollments as students_count' => function ($q) {
                    $q->where('status', 'enrolled');
                }
            ])
            ->orderByDesc('is_active')
            ->orderByDesc('created_at');

        if ($teacher) {
            $query->where('teacher_id', $teacher->id);
        }

        return response()->json([
            'classrooms' => $query->get(),
        ]);
    }

    public function show(Request $request, Classroom $classroom)
    {
        $user = $request->user();

        if ((int) $classroom->school_id !== (int) $user->school_id) {
            return $this->returnError('Unauthorized', 403);
        }

        $school = School::select('id', 'admin_email')->find($classroom->school_id);

        $userEmail = strtolower(trim((string) $user->email));
        $adminEmail = strtolower(trim((string) ($school->admin_email ?? '')));

        if ($adminEmail && $userEmail === $adminEmail) {
            return $this->classroomPayload($classroom);
        }

        $teacher = Teacher::where('school_id', $user->school_id)
            ->whereRaw('LOWER(email) = ?', [$userEmail])
            ->first();

        if (!$teacher || (int) $teacher->id !== (int) $classroom->teacher_id) {
            return $this->returnError('Unauthorized', 403);
        }

        return $this->classroomPayload($classroom);
    }

    private function classroomPayload(Classroom $classroom)
    {
        $enrollments = ClassroomEnrollment::where('classroom_id', $classroom->id)
            ->where('status', 'enrolled')
            ->with(['student:id,first_name,last_name,nickname,avatar'])
            ->orderByDesc('enrolled_at')
            ->get();

        return response()->json([
            'enrollments' => $enrollments,
            'classroom' => $classroom,
        ]);
    }


    public function create(StoreClassroomRequest $request)
    {
        $user = $request->user();

        if ($request->filled('teacher_id')) {
            $teacher = Teacher::where('id', $request->teacher_id)
                ->where('school_id', $user->school_id)
                ->firstOrFail();
        } else {
            // Find teacher record for the logged-in user
            $teacher = Teacher::where('school_id', $user->school_id)
                ->whereRaw('LOWER(email) = ?', [strtolower(trim((string) $user->email))])
                ->firstOrFail();
        }

        $joinCode = $this->generateUniqueJoinCode($teacher->school_id);

        $classroom = Classroom::create([
            'school_id' => $teacher->school_id,
            'teacher_id' => $teacher->id,
            'name' => $request->name,
            'join_code' => $joinCode,
            'start_date' => $request->start_date ?? now()->toDateString(),
            'end_date' => $request->end_date,
            'is_active' => true,
        ]);

        return response()->json([
            'classroom' => $classroom,
        ]);
    }

    public function update(UpdateClassroomRequest $request, Classroom $classroom)
    {
        $user = $request->user();

        if ((int) $classroom->school_id !== (int) $user->school_id) {
            return $this->returnError('Unauthorized', 403);
        }

        $school = School::select('id', 'admin_email')->find($classroom->school_id);

        $userEmail = strtolower(trim((string) $user->email));
        $adminEmail = strtolower(trim((string) ($school->admin_email ?? '')));

        $isAdmin = $adminEmail && $userEmail === $adminEmail;

        if (!$isAdmin) {
            $teacher = Teacher::where('school_id', $user->school_id)
                ->whereRaw('LOWER(email) = ?', [$userEmail])
                ->first();

            if (!$teacher || (int) $teacher->id !== (int) $classroom->teacher_id) {
                return $this->returnError('Unauthorized', 403);
            }
        }

        $data = $request->validated();

        unset($data['school_id'], $data['teacher_id']);

        $classroom->fill($data);
        $classroom->save();

        return response()->json([
            'classroom' => $classroom,
        ]);
    }

    public function archive(Request $request, Classroom $classroom)
    {
        $user = $request->user();

        if (!$classroom->is_active) {
            return response()->json(['classroom' => $classroom]);
        }

        if ((int) $classroom->school_id !== (int) $user->school_id) {
            return $this->returnError('Unauthorized', 403);
        }

        $school = School::select('id', 'admin_email')->find($classroom->school_id);

        $userEmail = strtolower(trim((string) $user->email));
        $adminEmail = strtolower(trim((string) ($school->admin_email ?? '')));

        $isAdmin = $adminEmail && $userEmail === $adminEmail;

        if (!$isAdmin) {
            $teacher = Teacher::where('school_id', $user->school_id)
                ->whereRaw('LOWER(email) = ?', [$userEmail])
                ->first();

            if (!$teacher || (int) $teacher->id !== (int) $classroom->teacher_id) {
                return $this->returnError('Unauthorized', 403);
            }
        }

        $classroom->is_active = false;
        $classroom->save();

        return response()->json([
            'classroom' => $classroom,
        ]);
    }

    public function completeStudent(Request $request, Classroom $classroom, Student $student)
    {
        $user = $request->user();

        if ((int) $classroom->school_id !== (int) $user->school_id) {
            return $this->returnError('Unauthorized', 403);
        }

        $school = School::select('id', 'admin_email')->find($classroom->school_id);

        $userEmail = strtolower(trim((string) $user->email));
        $adminEmail = strtolower(trim((string) ($school->admin_email ?? '')));

        $isAdmin = $adminEmail && $userEmail === $adminEmail;

        if (!$isAdmin) {
            $teacher = Teacher::where('school_id', $user->school_id)
                ->whereRaw('LOWER(email) = ?', [$userEmail])
                ->first();

            if (!$teacher || (int) $teacher->id !== (int) $classroom->teacher_id) {
                return $this->returnError('Unauthorized', 403);
            }
        }

        $enrollment = ClassroomEnrollment::where('classroom_id', $classroom->id)
            ->where('student_id', $student->id)
            ->first();

        if (!$enrollment) {
            return $this->returnError('Enrollment not found.', 404);
        }

        if ($enrollment->status === 'completed') {
            $this->setResult('enrollment', $enrollment);
            return $this->returnResponse();
        }

        $enrollment->status = 'completed';
        $enrollment->left_at = now();
        $enrollment->save();

        $this->setResult('enrollment', $enrollment);
        return $this->returnResponse();
    }


    public function regenerateJoinCode(Request $request, Classroom $classroom)
    {
        $user = $request->user();

        if ((int) $classroom->school_id !== (int) $user->school_id) {
            return $this->returnError('Unauthorized', 403);
        }

        $school = School::select('id', 'admin_email')->find($classroom->school_id);

        $userEmail = strtolower(trim((string) $user->email));
        $adminEmail = strtolower(trim((string) ($school->admin_email ?? '')));

        $isAdmin = $adminEmail && $userEmail === $adminEmail;

        if (!$isAdmin) {
            $teacher = Teacher::where('school_id', $user->school_id)
                ->whereRaw('LOWER(email) = ?', [$userEmail])
                ->first();

            if (!$teacher || (int) $teacher->id !== (int) $classroom->teacher_id) {
                return $this->returnError('Unauthorized', 403);
            }
        }

        DB::transaction(function () use ($classroom) {
            do {
                $newCode = ClassroomJoinCode::generate((int) $classroom->school_id);
            } while (Classroom::where('join_code', $newCode)->exists());

            $classroom->join_code = $newCode;
            $classroom->save();
        });

        $classroom->load(['teacher:id,name'])->loadCount([
            'enrollments as students_count' => fn($q) => $q->where('status', 'enrolled')
        ]);

        $this->setResult('classroom', $classroom);
        return $this->returnResponse();
    }


    public function students(Request $request, Classroom $classroom, Student $student)
    {
        $user = $request->user();

        if ((int) $classroom->school_id !== (int) $user->school_id) {
            return $this->returnError('Unauthorized', 403);
        }

        $school = School::select('id', 'admin_email')->find($classroom->school_id);
        $userEmail = strtolower(trim((string) $user->email));
        $adminEmail = strtolower(trim((string) ($school->admin_email ?? '')));

        $isAdmin = $adminEmail && $userEmail === $adminEmail;

        if (!$isAdmin) {
            $teacher = Teacher::where('school_id', $user->school_id)
                ->whereRaw('LOWER(email) = ?', [$userEmail])
                ->first();

            if (!$teacher || (int) $teacher->id !== (int) $classroom->teacher_id) {
                return $this->returnError('Unauthorized', 403);
            }
        }

        $enrollment = ClassroomEnrollment::where('classroom_id', $classroom->id)
            ->where('student_id', $student->id)
            ->first();

        if (!$enrollment) {
            return $this->returnError('Student is not part of this classroom.', 404);
        }

        $enrolledAt = $enrollment->enrolled_at
            ? Carbon::parse($enrollment->enrolled_at)
            : Carbon::parse($enrollment->created_at);

        $leftAt = $enrollment->left_at
            ? Carbon::parse($enrollment->left_at)
            : now();

        $enrolledMoment = $enrolledAt->copy();
        $leftMoment = $leftAt->copy();

        $intersectRange = function (Carbon $reqFrom, Carbon $reqTo) use ($enrolledMoment, $leftMoment) {
            $usedFrom = $reqFrom->copy();
            $usedTo = $reqTo->copy();

            if ($usedFrom->lt($enrolledMoment))
                $usedFrom = $enrolledMoment->copy();
            if ($usedTo->gt($leftMoment))
                $usedTo = $leftMoment->copy();

            if ($usedFrom->gt($usedTo))
                return [null, null];
            return [$usedFrom, $usedTo];
        };

        $rawType = strtolower((string) $request->query('type', 'week'));
        $type = match ($rawType) {
            'daily', 'day' => 'day',
            'weekly', 'week' => 'week',
            'monthly', 'month' => 'month',
            default => 'week',
        };

        $date = $request->query('date');
        $from = $request->query('from');
        $to = $request->query('to');
        $month = $request->query('month');

        $classroomId = null;

        $summary = null;

        if ($type === 'day') {
            $requested = $date ? Carbon::parse($date) : now();

            $reqFrom = $requested->copy()->startOfDay();
            $reqTo = $requested->copy()->endOfDay();

            [$usedFrom, $usedTo] = $intersectRange($reqFrom, $reqTo);

            if (!$usedFrom || !$usedTo) {
                $summary = [
                    'student_id' => $student->id,
                    'date' => $requested->toDateString(),
                    'stars_earned' => 0,
                    'stages_completed' => 0,
                    'time_spent_seconds' => 0,
                    'exercises_attempted' => 0,
                    'correct_attempts' => 0,
                    'accuracy' => 0,
                    'characters_practiced' => [],
                    'best_character' => null,
                    'needs_attention' => null,
                    'message' => 'Selected date is outside enrollment period.',
                ];
            } else {
                $summary = StudentSummary::getDailySummary(
                    $student->id,
                    $usedFrom->toDateString(),
                    $classroomId
                );
            }

            $summary['range'] = [
                'enrolled_at' => $enrolledMoment->toDateTimeString(),
                'left_at' => $leftMoment->toDateTimeString(),
                'requested_date' => $requested->toDateString(),
                'used_date' => $usedFrom?->toDateString(),
            ];
        } elseif ($type === 'month') {
            $monthStr = $month ?: now()->format('Y-m');

            $reqFrom = Carbon::createFromFormat('Y-m', $monthStr)->startOfMonth()->startOfDay();
            $reqTo = Carbon::createFromFormat('Y-m', $monthStr)->endOfMonth()->endOfDay();

            [$usedFrom, $usedTo] = $intersectRange($reqFrom, $reqTo);

            if (!$usedFrom || !$usedTo) {
                $summary = [
                    'student_id' => $student->id,
                    'month' => $monthStr,
                    'message' => 'No data in this month within enrollment period.',
                ];
            } else {
                $summary = StudentSummary::getMonthlySummary($student->id, $monthStr);
            }

            $summary['range'] = [
                'enrolled_at' => $enrolledMoment->toDateTimeString(),
                'left_at' => $leftMoment->toDateTimeString(),
                'requested_from' => $reqFrom->toDateString(),
                'requested_to' => $reqTo->toDateString(),
                'used_from' => $usedFrom?->toDateString(),
                'used_to' => $usedTo?->toDateString(),
            ];
        } else {
            $reqTo = $to
                ? Carbon::createFromFormat('Y-m-d', $to)->endOfDay()
                : now()->endOfDay();

            $reqFrom = $from
                ? Carbon::createFromFormat('Y-m-d', $from)->startOfDay()
                : $reqTo->copy()->subDays(6)->startOfDay();

            if ($reqFrom->gt($reqTo)) {
                [$reqFrom, $reqTo] = [
                    $reqTo->copy()->startOfDay(),
                    $reqFrom->copy()->endOfDay(),
                ];
            }

            [$usedFrom, $usedTo] = $intersectRange($reqFrom, $reqTo);

            if (!$usedFrom || !$usedTo) {
                $summary = [
                    'student_id' => $student->id,
                    'from_date' => $reqFrom->toDateString(),
                    'to_date' => $reqTo->toDateString(),
                    'total_stars_earned' => 0,
                    'total_stages_completed' => 0,
                    'total_time_spent_seconds' => 0,
                    'total_exercises_attempted' => 0,
                    'total_correct_attempts' => 0,
                    'accuracy' => 0,
                    'practice_days' => 0,
                    'characters_summary' => [],
                    'top_mastered_characters' => [],
                    'characters_to_review' => [],
                    'message' => 'Selected range is outside enrollment period.',
                ];
            } else {
                $summary = StudentSummary::getWeeklySummary(
                    $student->id,
                    $usedFrom->toDateString(),
                    $usedTo->toDateString(),
                    $classroomId
                );
            }

            $summary['range'] = [
                'enrolled_at' => $enrolledMoment->toDateTimeString(),
                'left_at' => $leftMoment->toDateTimeString(),
                'requested_from' => $reqFrom->toDateString(),
                'requested_to' => $reqTo->toDateString(),
                'used_from' => $usedFrom?->toDateString(),
                'used_to' => $usedTo?->toDateString(),
            ];
        }

        return response()->json([
            'classroom' => $classroom,
            'enrollment' => $enrollment,
            'student' => $student,
            'summary' => $summary,
        ]);
    }

    public function removeStudent(Request $request, Classroom $classroom, Student $student)
    {
        $user = $request->user();

        if ((int) $classroom->school_id !== (int) $user->school_id) {
            return $this->returnError('Unauthorized', 403);
        }

        $school = School::select('id', 'admin_email')->find($classroom->school_id);

        $userEmail = strtolower(trim((string) $user->email));
        $adminEmail = strtolower(trim((string) ($school->admin_email ?? '')));

        $isAdmin = $adminEmail && $userEmail === $adminEmail;

        if (!$isAdmin) {
            $teacher = Teacher::where('school_id', $user->school_id)
                ->whereRaw('LOWER(email) = ?', [$userEmail])
                ->first();

            if (!$teacher || (int) $teacher->id !== (int) $classroom->teacher_id) {
                return $this->returnError('Unauthorized', 403);
            }
        }

        $enrollment = ClassroomEnrollment::where('classroom_id', $classroom->id)
            ->where('student_id', $student->id)
            ->first();

        if (!$enrollment) {
            return $this->returnError('Enrollment not found.', 404);
        }

        if ($enrollment->status !== 'enrolled') {
            $this->setResult('enrollment', $enrollment);
            return $this->returnResponse();
        }

        $enrollment->status = 'removed';
        $enrollment->left_at = now();
        $enrollment->save();

        $this->setResult('enrollment', $enrollment);
        return $this->returnResponse();
    }

    private function generateUniqueJoinCode(int $schoolId): string
    {
        $expiredDays = 1;

        do {
            $code = ClassroomJoinCode::generate($schoolId, $expiredDays);
        } while (Classroom::where('join_code', $code)->exists());

        return $code;
    }
}
