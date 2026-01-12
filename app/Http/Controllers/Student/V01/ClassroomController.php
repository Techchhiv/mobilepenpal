<?php

namespace App\Http\Controllers\Student\V01;

use App\Http\Resources\Student\V01\Classroom\ClassroomDetailResource;
use App\Http\Resources\Student\V01\Classroom\ClassroomResource;
use App\Models\Classroom;
use App\Models\ClassroomEnrollment;
use App\Models\Student;
use Illuminate\Http\Request;

class ClassroomController extends Controller
{
    public function index()
    {
        /** @var Student|null $student */
        $student = auth('students')->user();

        if (!$student) {
            return $this->returnError('User not authenticated', 401);
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
            return $this->returnError('User not authenticated', 401);
        }

        $enrollment = ClassroomEnrollment::where('classroom_id', $classroom->id)
            ->where('student_id', $student->id)
            ->where('status', 'enrolled')
            ->first();

        if (!$enrollment) {
            return $this->returnError('Unauthorized', 403);
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
        $student = auth('students')->user();

        if (!$student) {
            return $this->returnError('Unauthenticated.', 401);
        }

        $validated = $request->validate([
            'join_code' => 'required|string|max:50',
        ]);

        $classroom = Classroom::where('join_code', $validated['join_code'])->first();
        if (!$classroom) {
            return $this->returnError('Invalid join code.', 404);
        }

        if (!$classroom->is_active) {
            return $this->returnError('This classroom is inactive.', 422);
        }

        if (!empty($student->school_id) && (int) $student->school_id !== (int) $classroom->school_id) {
            return $this->returnError('You cannot join a classroom from another school.', 403);
        }

        $enrollment = ClassroomEnrollment::updateOrCreate(
            ['classroom_id' => $classroom->id, 'student_id' => $student->id],
            ['status' => 'enrolled', 'enrolled_at' => now(), 'left_at' => null]
        );

        $student->current_classroom_id = $classroom->id;
        if (empty($student->school_id)) $student->school_id = $classroom->school_id;

        /** @var Student|null $student */
        $student->save();

        return response()->json([
            'classroom' => $classroom,
            'enrollment' => $enrollment,
        ]);
    }
}
