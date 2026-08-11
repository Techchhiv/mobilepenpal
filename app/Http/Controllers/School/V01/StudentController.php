<?php

namespace App\Http\Controllers\School\V01;

use App\Http\Controllers\Controller;
use App\Helpers\UploadMedia;
use App\Http\Requests\Student\V01\Auth\RegisterRequest;
use App\Http\Requests\Student\V01\User\UpdateUserRequest;
use App\Models\School;
use App\Models\Student;
use App\Models\Teacher;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;

use function App\Helpers\isValidPhone;

class StudentController extends Controller
{
    public function __construct()
    {
        require_once app_path('Helpers/PhoneNumberValidation.php');
    }
    public function index(Request $request)
    {
        $user = auth()->user();

        $schoolKey = null;

        $teacher = Teacher::query()
            ->select('school_key', 'school_id')
            ->where('email', $user->email)
            ->first();

        if ($teacher) {
            $schoolKey = $teacher->school_key;
        } else {
            $school = School::query()
                ->select('school_key', 'id')
                ->where('admin_email', $user->email)
                ->first();

            if ($school) {
                $schoolKey = $school->school_key;
            }
        }

        if (!$schoolKey) {
            return response()->json([
                'message' => 'Unable to determine your school. Please contact admin.'
            ], 403);
        }

        $q = Student::query()->where('school_key', $schoolKey);

        if ($request->filled('is_active')) {
            $q->where('is_active', filter_var($request->is_active, FILTER_VALIDATE_BOOLEAN));
        }

        if ($request->filled('search')) {
            $search = trim($request->search);
            $q->where(function ($qq) use ($search) {
                $qq->where('first_name', 'like', "%{$search}%")
                    ->orWhere('last_name', 'like', "%{$search}%")
                    ->orWhere('phone', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%");
            });
        }

        $perPage = (int) $request->query('per_page', 15);
        $students = $q->orderByDesc('id')->paginate(max(1, min($perPage, 100)));

        return response()->json([
            "student" => $students
        ]);
    }

    public function store(RegisterRequest $request)
    {
        $user = auth()->user();
        $schoolId = $user->school_id;
        $school = School::select('id', 'school_key')->find($schoolId);

        $validated = $request->validated();

        $validated['school_id'] = $schoolId;
        $validated['school_key'] = $school->school_key;

        if (!empty($validated['phone']) && !isValidPhone($validated['phone'])) {
            return response()->json([
                'message' => __('messages.valid_phone_number')
            ], 422);
        }

        $validated['password'] = Hash::make($validated['password']);
        if ($request->filled('avatar')) {
            $validated['avatar'] = UploadMedia::uploadImageBase64($request->input('avatar'));
        }

        $student = Student::create($validated);
        return response()->json([
            "student" => $student
        ]);
    }

    public function show(Student $student)
    {
        return response()->json([
            "student" => $student
        ]);
    }


    public function update(UpdateUserRequest $request, $id)
    {
        $student = Student::find($id);
        if (!$student) {
            return $this->returnError('Student not found.', 404);
        }

        $validated = $request->validated();

        if (array_key_exists('phone', $validated) && !empty($validated['phone']) && !isValidPhone($validated['phone'])) {
            return $this->returnError(__('messages.valid_phone_number'), 422);
        }

        if (!empty($validated['password'])) {
            $validated['password'] = Hash::make($validated['password']);
        } else {
            unset($validated['password']);
        }

        if (array_key_exists('avatar', $validated)) {
            if (empty($validated['avatar'])) {
                $validated['avatar'] = null;
            } else {
                if (!empty($student->avatar)) {
                    $previousPath = public_path($student->avatar);
                    if (file_exists($previousPath)) {
                        @unlink($previousPath);

                        $folder = dirname($previousPath);
                        while (
                            $folder !== public_path('images') &&
                            is_dir($folder) &&
                            count(scandir($folder)) === 2
                        ) {
                            @rmdir($folder);
                            $folder = dirname($folder);
                        }
                    }
                }
                $path = UploadMedia::uploadImageBase64($validated['avatar']);
                if (!$path) {
                    return $this->returnError('Incorrect Image type or wrong format', 422);
                }
                $validated['avatar'] = $path;
            }
        }

        $student->update($validated);
        return response()->json($student);
    }

    public function destroy($id)
    {
        $student = Student::find($id);
        if (!$student) {
            return $this->returnError('Student not found.', 404);
        }

        if (!empty($student->avatar)) {
            $previousPath = public_path($student->avatar);
            if (file_exists($previousPath)) {
                @unlink($previousPath);

                $folder = dirname($previousPath);
                while ($folder !== public_path('images') && is_dir($folder) && count(scandir($folder)) === 2) {
                    @rmdir($folder);
                    $folder = dirname($folder);
                }
            }
        }

        $student->delete();

        return $this->returnSuccess('Deleted');
    }
}
