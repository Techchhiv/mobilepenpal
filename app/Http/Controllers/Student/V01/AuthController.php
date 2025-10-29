<?php

namespace App\Http\Controllers\Student\V01;

use App\Http\Requests\Student\V01\Auth\LoginRequest;
use App\Http\Requests\Student\V01\Auth\RegisterRequest;
use App\Models\Student;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpFoundation\JsonResponse;
use function App\Helpers\isKhmerPhone;

class AuthController extends Controller
{
    public function __construct()
    {
        require_once app_path('Helpers/PhoneNumberValidation.php');
    }

    public function register(RegisterRequest $request): JsonResponse
    {
        $validated = $request->validated();

        if (!isKhmerPhone($validated['phone']) || !isKhmerPhone($validated['parent_phone'])) {
            return $this->returnError("The phone number must be a valid Cambodian number.", 422);
        }

        $validated['password'] = Hash::make($validated['password']);

        $student = Student::create($validated);

        $token = $student->createToken('student_token')->plainTextToken;

        $this->setResult("token", $token);
        $this->setResult("student", $student);
        return $this->returnResponse();
    }

    public function login(LoginRequest $request): JsonResponse
    {
        $validated = $request->validated();

        $student = Student::where('school_key', $validated['school_key'])
            ->where(function ($query) use ($validated) {
                $query->where('phone', $validated['identifier'])
                    ->orWhere('email', $validated['identifier']);
            })
            ->first();

        if (!$student || !Hash::check($validated['password'], $student->password)) {
            return $this->returnError('The provided credentials are incorrect.', 401);
        }

        $token = $student->createToken('student_token')->plainTextToken;

        $this->setResult("token", $token);
        $this->setResult("student", $student);
        return $this->returnResponse();
    }

    public function logout(): JsonResponse
    {
        auth('students')->user()->tokens()->delete();

        return $this->returnSuccess("ok");
    }

    public function check(Request $request): JsonResponse
    {
        $student = $request->user();

        $this->setResult("student", $student);
        return $this->returnResponse();
    }
}
