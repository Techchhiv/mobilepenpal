<?php

namespace App\Http\Controllers;

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
            ->with(['teacher']) // keep teacher info
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
            'classroom'   => $classroom,
        ]);
    }


    public function create(StoreClassroomRequest $request)
    {
        $teacher = Teacher::where('id', $request->teacher_id)
            ->where('school_id', $request->user()->school_id)
            ->firstOrFail();

        $joinCode = $this->generateUniqueJoinCode($teacher->school_id);

        $classroom = Classroom::create([
            'school_id'  => $teacher->school_id,
            'teacher_id' => $teacher->id,
            'name'       => $request->name,
            'join_code' => $joinCode,
            'start_date' => $request->start_date ?? now()->toDateString(),
            'end_date'   => $request->end_date,
            'is_active'  => true,
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

        $userEmail  = strtolower(trim((string) $user->email));
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

        $userEmail  = strtolower(trim((string) $user->email));
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

    public function students(Request $request, Classroom $classroom, Student $student)
    {
        $user = $request->user(); // users table

        if ((int) $classroom->school_id !== (int) $user->school_id) {
            return $this->returnError('Unauthorized', 403);
        }

        $school = School::select('id', 'admin_email')->find($classroom->school_id);
        $userEmail  = strtolower(trim((string) $user->email));
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

        $leftAt = $enrollment->left_at ? Carbon::parse($enrollment->left_at) : now();

        $type = $request->query('type', 'weekly');
        $date = $request->query('date');
        $from = $request->query('from');
        $to   = $request->query('to');
        $month = $request->query('month');

        $clampDate = function (Carbon $d) use ($enrolledAt, $leftAt) {
            if ($d->lt($enrolledAt)) return $enrolledAt->copy();
            if ($d->gt($leftAt)) return $leftAt->copy();
            return $d;
        };

        if ($type === 'daily') {
            $d = $date ? Carbon::parse($date) : now();
            $d = $clampDate($d);

            $summary = StudentSummary::getDailySummary($student->id, $d->toDateString());
            $summary['range'] = [
                'enrolled_at' => $enrolledAt->toDateTimeString(),
                'left_at' => $leftAt->toDateTimeString(),
                'clamped_date' => $d->toDateString(),
            ];
        } elseif ($type === 'monthly') {
            $monthStr = $month ?: now()->format('Y-m');
            $mFrom = Carbon::createFromFormat('Y-m', $monthStr)->startOfMonth();
            $mTo = Carbon::createFromFormat('Y-m', $monthStr)->endOfMonth();

            $cFrom = $clampDate($mFrom);
            $cTo = $clampDate($mTo);

            if ($cFrom->gt($cTo)) {
                $summary = [
                    'student_id' => $student->id,
                    'month' => $monthStr,
                    'message' => 'No data in this month within enrollment period.',
                ];
            } else {
                $summary = StudentSummary::getWeeklySummary($student->id, $cFrom->toDateString(), $cTo->toDateString());
                $summary['month'] = $monthStr;
                $summary['range'] = [
                    'enrolled_at' => $enrolledAt->toDateTimeString(),
                    'left_at' => $leftAt->toDateTimeString(),
                    'from_date' => $cFrom->toDateString(),
                    'to_date' => $cTo->toDateString(),
                ];
            }
        } else {
            $defaultTo = $clampDate(now());
            $defaultFrom = $clampDate($defaultTo->copy()->subDays(6));

            $fromDate = $from ? $clampDate(Carbon::parse($from))->toDateString() : $defaultFrom->toDateString();
            $toDate = $to ? $clampDate(Carbon::parse($to))->toDateString() : $defaultTo->toDateString();

            if (Carbon::parse($fromDate)->gt(Carbon::parse($toDate))) {
                [$fromDate, $toDate] = [$toDate, $fromDate];
            }

            $summary = StudentSummary::getWeeklySummary($student->id, $fromDate, $toDate);
            $summary['range'] = [
                'enrolled_at' => $enrolledAt->toDateTimeString(),
                'left_at' => $leftAt->toDateTimeString(),
                'from_date' => $fromDate,
                'to_date' => $toDate,
            ];
        }

        return response()->json([
            'classroom'  => $classroom,
            'enrollment' => $enrollment,
            'student'    => $student,
            'summary'    => $summary,
        ]);
    }

    public function removeStudent(Request $request, Classroom $classroom, Student $student)
    {
        $teacher = $request->user();

        if (
            (int)$classroom->teacher_id !== (int)$teacher->id ||
            (int)$classroom->school_id !== (int)$teacher->school_id
        ) {
            return $this->returnError('Unauthorized', 403);
        }

        $enrollment = ClassroomEnrollment::where('classroom_id', $classroom->id)
            ->where('student_id', $student->id)
            ->first();

        if (!$enrollment) {
            return $this->returnError('Enrollment not found.', 404);
        }

        if ($enrollment->status === 'removed') {
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
        $schoolKey = School::where('id', $schoolId)->value('school_key');
        $prefix = $schoolKey ? strtoupper($schoolKey) : 'SCH';

        do {
            $random = strtoupper(Str::random(8));
            $code = "{$prefix}-{$random}";
        } while (Classroom::where('join_code', $code)->exists());

        return $code;
    }
}
