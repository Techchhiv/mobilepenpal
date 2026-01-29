<?php

namespace App\Http\Controllers\Student\V01;

use App\Http\Requests\Student\V01\Auth\LoginRequest;
use App\Http\Requests\Student\V01\Auth\RegisterRequest;
use App\Http\Requests\Student\V01\Auth\VerifyOtpRequest;
use App\Http\Resources\Student\V01\User\UserDetailResource;
use App\Models\Student;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpFoundation\JsonResponse;

use function App\Helpers\isKhmerPhone;
use function App\Helpers\uploadImageBase64;

class AuthController extends Controller
{

    private $firebaseAuth;

    public function __construct()
    {
        require_once app_path('Helpers/PhoneNumberValidation.php');
        require_once app_path('Helpers/UploadMedia.php');
        // $this->firebaseAuth = (new Factory)
        //     ->withServiceAccount(config('firebase.credentials'))
        //     ->createAuth();
    }

    public function register(RegisterRequest $request): JsonResponse
    {
        $validated = $request->validated();

        if (!isKhmerPhone($validated['phone'])) {
            return $this->returnError("The phone number must be a valid Cambodian number.", 422);
        }

        // $userInfo = [
        //     'phoneNumber' => ChangePhoneNumberFormat::toE164GlobalFormat($validated['phone']),
        //     'displayName' => $validated['first_name'] . ' ' . $validated['last_name'] ?? null,
        // ];

        // $firebaseUser = $this->firebaseAuth->createUser($userInfo);
        // $firebaseUid = $firebaseUser->uid;
        // $validated['firebase_uid'] = $firebaseUid;

        $validated['school_id'] = $validated['school_id'] ?? null;
        $validated['school_key'] = $validated['school_key'] ?? null;
        $validated['password'] = Hash::make($validated['password']);

        if (!empty($validated['avatar'])) {
            $validated['avatar'] = uploadImageBase64($validated['avatar']);
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

        $student = Student::where('phone', $validated['phone'])
            ->first();

        if (!$student || !Hash::check($validated['password'], $student->password)) {
            return $this->returnError('The provided credentials are incorrect.', 401);
        }

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
                $query->where('phone', $validated['identifier'])
                    ->orWhere('email', $validated['identifier']);
            })
            ->first();

        if (!$student || !Hash::check($validated['password'], $student->password)) {
            return $this->returnError('The provided credentials are incorrect.', 401);
        }
        $token = $student->createToken('student_token')->plainTextToken;

        $this->setResult("student", $student);
        $this->setResult("token", $token);
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

    public function verifyOtp(VerifyOtpRequest $request): JsonResponse
    {
        $validated = $request->validated();

        try {
            $verifiedIdToken = $this->firebaseAuth->verifyIdToken($validated['firebase_token']);
            $firebaseUid = $verifiedIdToken->claims()->get('sub');

            $student = Student::where('firebase_uid', $firebaseUid)->first();

            if (!$student) {
                return $this->returnError('Student not found.', 404);
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
            return $this->returnError('Invalid Firebase token.', 401);
        } catch (\Kreait\Firebase\Exception\Auth\UserNotFound $e) {
            return $this->returnError('Firebase user not found.', 404);
        } catch (\Exception $e) {
            Log::error('OTP verification failed: ' . $e->getMessage());
            return $this->returnError('OTP verification failed.', 500);
        }
    }
}
