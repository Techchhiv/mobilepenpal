<?php

namespace App\Http\Controllers\Teacher\V01;

use App\Http\Requests\Teacher\V01\StoreClassroomRequest;
use App\Http\Requests\Teacher\V01\UpdateClassroomRequest;
use App\Models\Branch;
use App\Models\Classroom;
use App\Models\ClassroomEnrollment;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class ClassroomController extends Controller
{
    public function index(Request $request)
    {
        $teacher = $request->user();

        $classrooms = Classroom::where('teacher_id', $teacher->id)
            ->orderByDesc('is_active')
            ->orderByDesc('created_at')
            ->get();

        $this->setResult('classrooms', $classrooms);
        return $this->returnResponse();
    }

    public function show(Request $request, Classroom $classroom)
    {
        $teacher = $request->user();

        if ($classroom->teacher_id !== $teacher->id) {
            return $this->returnError('Unauthorized', 403);
        }

        $enrollments = ClassroomEnrollment::where('classroom_id', $classroom->id)
            ->where('status', 'enrolled')
            ->with('student')
            ->get();

        $this->setResult('classroom', $classroom);
        $this->setResult('enrollments', $enrollments);
        return $this->returnResponse();
    }

    public function create(StoreClassroomRequest $request)
    {
        $teacher = $request->user();

        $joinCode = $this->generateUniqueJoinCode($request->branch_id);

        $classroom = Classroom::create([
            'branch_id'   => $request->branch_id,
            'teacher_id'  => $teacher->id,
            'name'        => $request->name,
            'join_code'   => $joinCode,
            // 'grade_level' => $request->grade_level ?? '',
            // 'subject'     => $request->subject,
            'start_date'  => $request->start_date ?? now()->toDateString(),
            'end_date'    => $request->end_date,
            'is_active'   => true,
        ]);

        $this->setResult('classroom', $classroom);
        return $this->returnResponse();
    }

    public function update(UpdateClassroomRequest $request, Classroom $classroom)
    {
        $teacher = $request->user();

        if ($classroom->teacher_id !== $teacher->id) {
            return $this->returnError('Unauthorized', 403);
        }

        $classroom->fill($request->validated());
        $classroom->save();

        $this->setResult('classroom', $classroom);
        return $this->returnResponse();
    }

    private function generateUniqueJoinCode(int $branchId): string
    {
        $branchCode = Branch::where('id', $branchId)->value('branch_code');

        $prefix = $branchCode ? strtoupper($branchCode) : 'BR';

        do {
            $random = strtoupper(Str::random(8));
            $code = "{$prefix}-{$random}";
        } while (Classroom::where('join_code', $code)->exists());

        return $code;
    }
}
