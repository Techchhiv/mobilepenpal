<?php

namespace App\Http\Controllers\Student\V01;

use App\Helpers\ClassroomJoinCode;
use App\Http\Resources\Student\V01\Classroom\ClassroomDetailResource;
use App\Http\Resources\Student\V01\Classroom\ClassroomResource;
use App\Models\Classroom;
use App\Models\ClassroomEnrollment;
use App\Models\Student;
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
                    $q->select('id', 'teacher_id', 'name', 'is_active')
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

        $classroom->setRelation('enrollment', $enrollment);
        $classroom->setRelation('classmates', $students);

        $this->setResult('classroom', new ClassroomDetailResource($classroom));
        return $this->returnResponse();
    }


    public function joinByCode(Request $request)
    {
        /** @var Student|null $student */
        $student = auth('students')->user();
        if (!$student) return $this->returnError(__('messages.unauthenticated'), 401);

        $validated = $request->validate([
            'join_code' => 'required|string|max:50',
        ]);

        $joinCode = strtoupper(trim($validated['join_code']));

        return DB::transaction(function () use ($student, $joinCode) {

            $studentLocked = Student::whereKey($student->id)->lockForUpdate()->first();

            if (empty($studentLocked->school_id)) {
                return $this->returnError(
                    __('messages.account_not_linked'),
                    403
                );
            }

            $classroom = Classroom::where('join_code', $joinCode)
                ->where('school_id', $studentLocked->school_id)
                ->first();

            if (!$classroom) return $this->returnError(__('messages.invalid_join_code'), 404);
            if (!$classroom->is_active) return $this->returnError(__('messages.classroom_inactive'), 422);

            $check = ClassroomJoinCode::validate($classroom->join_code, (int) $classroom->school_id);

            if ($check && !$check['ok']) {
                return $this->returnError($check['reason'] ?? __('messages.invalid_join_code'), 422);
            }

            if ($check && !empty($check['expired'])) {
                return $this->returnError(
                    __('messages.join_code_expired'),
                    410
                );
            }

            $activeEnrollment = ClassroomEnrollment::where('student_id', $studentLocked->id)
                ->where('status', 'enrolled')
                ->lockForUpdate()
                ->first();

            if ($activeEnrollment && (int)$activeEnrollment->classroom_id !== (int)$classroom->id) {
                return $this->returnError(
                    __('messages.already_enrolled'),
                    409
                );
            }
            $enrollment = ClassroomEnrollment::updateOrCreate(
                ['classroom_id' => $classroom->id, 'student_id' => $studentLocked->id],
                ['status' => 'enrolled', 'enrolled_at' => now(), 'left_at' => null]
            );

            $classroom->load(['teacher:id,name'])->loadCount([
                'enrollments as students_count' => fn($q) => $q->where('status', 'enrolled')
            ]);

            $classroom->setRelation('enrollment', $enrollment);

            $this->setResult('classroom', new ClassroomResource($classroom));
            return $this->returnResponse();
        });
    }
}
