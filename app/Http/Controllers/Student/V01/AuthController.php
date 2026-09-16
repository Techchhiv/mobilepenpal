<?php

namespace App\Http\Controllers\Student\V01;

use App\Helpers\UploadMedia;
use App\Http\Requests\Student\V01\Auth\LoginRequest;
use App\Http\Requests\Student\V01\Auth\RegisterRequest;
use App\Http\Requests\Student\V01\Auth\VerifyOtpRequest;
use App\Http\Resources\Student\V01\User\UserDetailResource;
use App\Models\Student;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpFoundation\JsonResponse;

use function App\Helpers\isValidPhone;

class AuthController extends Controller
{

    private $firebaseAuth;

    public function __construct()
    {
        require_once app_path('Helpers/PhoneNumberValidation.php');
        // $this->firebaseAuth = (new Factory)
        //     ->withServiceAccount(config('firebase.credentials'))
        //     ->createAuth();
    }

    private function findStudentByPhone(string $phone): ?Student
    {
        $cleanPhone = preg_replace('/[^\d+]/', '', $phone);

        return Student::where(function ($query) use ($phone, $cleanPhone) {
            $query->where('phone', $phone)
                  ->orWhere('phone', $cleanPhone);
            try {
                $phoneUtil = \libphonenumber\PhoneNumberUtil::getInstance();
                $proto = $phoneUtil->parse($cleanPhone, 'KH');
                if ($phoneUtil->isValidNumber($proto)) {
                    $e164 = $phoneUtil->format($proto, \libphonenumber\PhoneNumberFormat::E164);
                    $national = '0' . $proto->getNationalNumber();
                    $nationalRaw = (string)$proto->getNationalNumber();
                    $query->orWhere('phone', $e164)
                          ->orWhere('phone', $national)
                          ->orWhere('phone', $nationalRaw);
                }
            } catch (\Exception $e) {
                // Ignore parsing errors
            }
        })->first();
    }

    public function checkExists(Request $request): JsonResponse
    {
        $phone = trim($request->input('phone') ?? '');
        $email = trim($request->input('email') ?? '');

        if (empty($phone) && empty($email)) {
            return $this->returnError(__('messages.validation_error'), 422);
        }

        // 1. Check phone if provided
        if (!empty($phone)) {
            $existingStudent = $this->findStudentByPhone($phone);
            if ($existingStudent) {
                return response()->json([
                    'code' => 409,
                    'message' => __('messages.phone_already_registered'),
                    'data' => null,
                    'errors' => [
                        'phone' => [__('messages.phone_already_registered')]
                    ],
                    'timestamp' => \Carbon\Carbon::now()->toDateTimeString(),
                ], 409);
            }
        }

        // 2. Check email if provided
        if (!empty($email)) {
            $emailExists = Student::where('email', strtolower($email))->exists();
            if ($emailExists) {
                return response()->json([
                    'code' => 409,
                    'message' => __('messages.email_already_registered'),
                    'data' => null,
                    'errors' => [
                        'email' => [__('messages.email_already_registered')]
                    ],
                    'timestamp' => \Carbon\Carbon::now()->toDateTimeString(),
                ], 409);
            }
        }

        return $this->returnSuccess(__('messages.user_available'), ['exists' => false]);
    }

    public function register(RegisterRequest $request): JsonResponse
    {
        $validated = $request->validated();

        if (!empty($validated['phone']) && !isValidPhone($validated['phone'])) {
            return $this->returnError(__('messages.valid_phone_number'), 422);
        }

        if (!empty($validated['phone'])) {
            $existingStudent = $this->findStudentByPhone($validated['phone']);
            if ($existingStudent) {
                return response()->json([
                    'code' => 422,
                    'message' => __('messages.phone_already_registered'),
                    'data' => null,
                    'errors' => [
                        'phone' => [__('messages.phone_already_registered')]
                    ],
                    'timestamp' => \Carbon\Carbon::now()->toDateTimeString(),
                ], 422);
            }
        }

        $validated['school_id'] = $validated['school_id'] ?? null;
        $validated['school_key'] = $validated['school_key'] ?? null;
        $validated['phone'] = $validated['phone'] ?? null;
        $validated['password'] = Hash::make($validated['password']);

        if (!empty($validated['avatar'])) {
            $validated['avatar'] = UploadMedia::uploadImageBase64($validated['avatar']);
        } else {
            $validated['avatar'] = null;
        }

        if (!empty($validated['date_of_birth'])) {
            $validated['age'] = \Carbon\Carbon::parse($validated['date_of_birth'])->age;
        }

        $student = Student::create($validated);
        $token = $student->createToken('students')->plainTextToken;

        $this->setResult("student", $student);
        $this->setResult("token", $token);
        return $this->returnResponse();
    }

    public function login(LoginRequest $request): JsonResponse
    {
        $validated = $request->validated();

        $loginInput = trim($validated['login'] ?? $validated['email'] ?? $validated['phone'] ?? '');

        $student = null;

        if (!empty($loginInput)) {
            // If identifier contains '@', try email lookup first
            if (str_contains($loginInput, '@')) {
                $email = strtolower($loginInput);
                $student = Student::where('email', $email)->first();
            } else {
                // Otherwise try phone lookup first
                $student = $this->findStudentByPhone($loginInput);
            }

            // Fallback lookup across both columns if specific lookup yielded no student
            if (!$student) {
                $student = Student::where('email', strtolower($loginInput))
                    ->orWhere('phone', $loginInput)
                    ->first();
            }
        }

        if (!$student || !Hash::check($validated['password'], $student->password)) {
            return $this->returnError(__('messages.credentials_incorrect'), 401);
        }

        if (!$student->is_active) {
            return $this->returnError(__('messages.student_inactive'), 403);
        }

        // Check if there are active tokens for this student (Disabled for now)
        // $hasActiveSessions = $student->tokens()->exists();

        // if ($hasActiveSessions && empty($validated['confirm'])) {
        //     return $this->returnError('already_logged_in', 409);
        // }

        $student->tokens()->delete();

        $token = $student->createToken('student_token')->plainTextToken;

        $this->setResult("student", new UserDetailResource($student));
        $this->setResult("token", $token);
        return $this->returnResponse();
    }

    public function login_test(LoginRequest $request): JsonResponse
    {
        $validated = $request->validated();

        $student = Student::where('school_key', $validated['school_key'])
            ->where(function ($query) use ($validated) {
                $identifier = $validated['identifier'];
                $query->where('email', $identifier)
                    ->orWhere('phone', $identifier);
                try {
                    $phoneUtil = \libphonenumber\PhoneNumberUtil::getInstance();
                    $proto = $phoneUtil->parse($identifier, 'KH');
                    if ($phoneUtil->isValidNumber($proto)) {
                        $e164 = $phoneUtil->format($proto, \libphonenumber\PhoneNumberFormat::E164);
                        $national = '0' . $proto->getNationalNumber();
                        $query->orWhere('phone', $e164)
                            ->orWhere('phone', $national);
                    }
                } catch (\Exception $e) {
                    // Ignore
                }
            })
            ->first();

        if (!$student || !Hash::check($validated['password'], $student->password)) {
            return $this->returnError(__('messages.credentials_incorrect'), 401);
        }

        if (!$student->is_active) {
            return $this->returnError(__('messages.student_inactive'), 403);
        }
        $token = $student->createToken('student_token')->plainTextToken;

        $this->setResult("student", $student);
        $this->setResult("token", $token);
        return $this->returnResponse();
    }

    public function logout(Request $request): JsonResponse
    {
        $user = $request->user();
        if ($user) {
            $user->tokens()->delete();
        }

        return $this->returnSuccess("ok");
    }

    public function check(Request $request): JsonResponse
    {
        $student = $request->user();

        $this->setResult("student", $student);
        return $this->returnResponse();
    }

    public function verifyOtp(VerifyOtpRequest $request): JsonResponse
    {
        $validated = $request->validated();

        try {
            $verifiedIdToken = $this->firebaseAuth->verifyIdToken($validated['firebase_token']);
            $firebaseUid = $verifiedIdToken->claims()->get('sub');

            $student = Student::where('firebase_uid', $firebaseUid)->first();

            if (!$student) {
                return $this->returnError(__('messages.student_not_found'), 404);
            }

            // $firebaseUser = $this->firebaseAuth->getUser($firebaseUid);
            // $firebasePhone = $firebaseUser->phoneNumber;
            // $firebasePhoneNumber = ChangePhoneNumberFormat::toLocalKhmerFormat($firebasePhone);
            // $khPhoneFormat = ChangePhoneNumberFormat::toLocalKhmerFormat($validated['phone']);

            // if ($firebasePhoneNumber !== $khPhoneFormat) {
            //     return $this->returnError('Phone number mismatch.', 401);
            // }

            $token = $student->createToken('student_session_token')->plainTextToken;

            $this->setResult("token", $token);
            $this->setResult("student", $student);
            return $this->returnResponse();
        } catch (\Kreait\Firebase\Exception\Auth\FailedToVerifyToken $e) {
            return $this->returnError(__('messages.invalid_firebase_token'), 401);
        } catch (\Kreait\Firebase\Exception\Auth\UserNotFound $e) {
            return $this->returnError(__('messages.firebase_user_not_found'), 404);
        } catch (\Exception $e) {
            Log::error('OTP verification failed: ' . $e->getMessage());
            return $this->returnError(__('messages.otp_verification_failed'), 500);
        }
    }
}
