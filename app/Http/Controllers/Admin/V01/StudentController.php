<?php

namespace App\Http\Controllers\Admin\V01;

use App\Helpers\UploadMedia;
use App\Http\Requests\Admin\Student\StoreStudentRequest;
use App\Http\Requests\Admin\Student\UpdateStudentRequest;
use App\Models\School;
use App\Models\Student;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

use function App\Helpers\isValidPhone;

class StudentController extends Controller
{
    public function __construct()
    {
        parent::__construct();
        require_once app_path('Helpers/PhoneNumberValidation.php');
    }

    public function index(Request $request): JsonResponse
    {
        $q = Student::query();

        if ($request->filled('school_affiliation')) {
            $affiliation = $request->query('school_affiliation');
            if ($affiliation === 'school') {
                $q->whereNotNull('school_id');
            } elseif ($affiliation === 'public') {
                $q->whereNull('school_id');
            }
        }

        if ($request->filled('school_id')) {
            $q->where('school_id', (int) $request->query('school_id'));
        }
        if ($request->filled('is_active')) {
            $q->where('is_active', filter_var($request->is_active, FILTER_VALIDATE_BOOLEAN));
        }

        if ($request->filled('search')) {
            $search = trim($request->search);
            $q->where(function ($qq) use ($search) {
                $qq->where('first_name', 'like', "%{$search}%")
                    ->orWhere('last_name', 'like', "%{$search}%")
                    ->orWhere('phone', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%")
                    ->orWhere('nickname', 'like', "%{$search}%");
            });
        }

        $perPage = (int) $request->query('per_page', 15);
        $students = $q->orderByDesc('id')->paginate(max(1, min($perPage, 100)));

        $this->setResult('students', $students);
        return $this->returnResponse();
    }

    public function store(StoreStudentRequest $request): JsonResponse
    {
        $validated = $request->validated();

        if (!isValidPhone($validated['phone'])) {
            return $this->returnError(__('messages.valid_phone_number'), 422);
        }

        if (!empty($validated['school_id'])) {
            $school = School::find($validated['school_id']);
            if ($school) {
                $validated['school_key'] = $school->school_key;
            }
        } else {
            $validated['school_id'] = null;
            $validated['school_key'] = null;
        }

        $validated['password'] = Hash::make($validated['password']);

        if ($request->filled('avatar')) {
            $path = UploadMedia::uploadImageBase64($validated['avatar']);
            if (!$path) {
                return $this->returnError('Incorrect Image type or wrong format', 422);
            }
            $validated['avatar'] = $path;
        }

        $student = Student::create($validated);

        $this->setResult('student', $student);
        return $this->returnResponse(201);
    }

    public function show(int $id): JsonResponse
    {
        $student = Student::find($id);
        if (!$student) {
            return $this->returnError('Student not found.', 404);
        }

        $this->setResult('student', $student);
        return $this->returnResponse();
    }

    public function update(UpdateStudentRequest $request, int $id): JsonResponse
    {
        $student = Student::find($id);
        if (!$student) {
            return $this->returnError('Student not found.', 404);
        }

        $validated = $request->validated();

        if (array_key_exists('phone', $validated) && !empty($validated['phone']) && !isValidPhone($validated['phone'])) {
            return $this->returnError(__('messages.valid_phone_number'), 422);
        }

        if (array_key_exists('school_id', $validated)) {
            if (!empty($validated['school_id'])) {
                $school = School::find($validated['school_id']);
                if ($school) {
                    $validated['school_key'] = $school->school_key;
                }
            } else {
                $validated['school_id'] = null;
                $validated['school_key'] = null;
            }
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

        $this->setResult('student', $student->fresh());
        return $this->returnResponse();
    }

    public function toggle(int $id): JsonResponse
    {
        $student = Student::find($id);
        if (!$student) {
            return $this->returnError('Student not found.', 404);
        }

        $student->is_active = !$student->is_active;
        $student->save();

        $this->setResult('student', $student);
        return $this->returnResponse();
    }

    public function destroy(int $id): JsonResponse
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

        return $this->returnSuccess('Student deleted successfully.');
    }
}
