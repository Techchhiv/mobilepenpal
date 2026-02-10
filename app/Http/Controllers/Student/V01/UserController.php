<?php

namespace App\Http\Controllers\Student\V01;

use App\Http\Requests\Student\V01\User\UpdateUserRequest;
use App\Http\Resources\Student\V01\User\UserDetailResource;
use App\Helpers\StudentProgress;
use App\Helpers\StudentSummary;
use App\Models\Classroom;
use App\Models\ClassroomEnrollment;
use App\Models\Student;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpFoundation\JsonResponse;

use function App\Helpers\uploadImageBase64;

class UserController extends Controller
{

    public function __construct()
    {
        require_once app_path('Helpers/UploadMedia.php');
    }
    public function profile(): JsonResponse
    {
        $authUser = auth::guard('students')->user();

        if (!$authUser) {
            return $this->returnError('User not authenticated', 401);
        }

        $studentProgress = new StudentProgress();

        $this->setResult("profile", new UserDetailResource($authUser));
        $this->setResult(
            "progress",
            $studentProgress->getWorldsWithProgress()
        );
        return $this->returnResponse();
    }

    public function update(UpdateUserRequest $request): JsonResponse
    {
        /** @var Student $student */
        $student = Auth::user();

        if (!$student) {
            return $this->returnError('User not authenticated', 401);
        }

        $validated = $request->validated();

        $student->update($validated);

        $this->setResult('students', new UserDetailResource($student));
        return $this->returnResponse();
    }
    public function updatePassword(Request $request): JsonResponse
    {
        $request->validate([
            'current_password' => 'required|string',
            'new_password' => 'required|string|min:6|confirmed',
        ]);

        /** @var Student $student */
        $student = Auth::user();

        if (!Hash::check($request->current_password, $student->password)) {
            return $this->returnError('Current password is incorrect', 422);
        }

        $student->update([
            'password' => Hash::make($request->new_password)
        ]);

        return $this->returnSuccess();
    }

    public function updateParentPin(Request $request): JsonResponse
    {
        $request->validate([
            'parent_pin' => 'required|string|min:4|max:6',
        ]);

        /** @var Student $student */
        $student = Auth::user();

        $student->update([
            'parent_pin' => $request["parent_pin"]
        ]);

        $this->setResult('parent_pin', $request["parent_pin"]);
        return $this->returnResponse();
    }

    public function switchMode(): JsonResponse
    {
        /** @var Student $student */
        $student = Auth::user();

        $newMode = $student["mode"] === 'student' ? 'parent' : 'student';

        $student->update([
            'mode' => $newMode
        ]);

        $this->setResult('mode', $newMode);
        return $this->returnResponse();
    }

    public function checkParentPin(): JsonResponse
    {
        /** @var Student $student */
        $student = Auth::user();

        $isPinSet = !empty($student->parent_pin);

        $this->setResult('is_parent_pin_set', $isPinSet);
        return $this->returnResponse();
    }

    public function updateImage(Request $request): JsonResponse
    {
        $request->validate([
            'image' => 'required|string'
        ]);

        /** @var Student $student */
        $student = Auth::user();

        if (!$student) {
            return $this->returnError('User not authenticated', 401);
        }

        if ($student->avatar) {
            $previousPath = public_path($student->avatar);
            if (file_exists($previousPath)) {
                unlink($previousPath);

                $folder = dirname($previousPath);
                while ($folder !== public_path('images') && is_dir($folder) && count(scandir($folder)) === 2) {
                    rmdir($folder);
                    $folder = dirname($folder);
                }
            }
        }

        $imagePath = uploadImageBase64($request->image);

        if (!$imagePath) {
            return $this->returnError('Incorrect Image type or wrong format', 422);
        }

        $student->update([
            'avatar' => $imagePath
        ]);

        $this->setResult('student', new UserDetailResource($student));
        return $this->returnResponse();
    }

    public function dailySummary(Request $request): JsonResponse
    {
        /** @var Student|null $student */
        $student = auth::guard('students')->user();

        if (!$student) {
            return $this->returnError('User not authenticated', 401);
        }

        $date = $request->query('date', Carbon::now()->toDateString());

        $summary = StudentSummary::getDailySummary($student->id, $date);

        $this->setResult('summary', $summary);
        return $this->returnResponse();
    }

    public function weeklySummary(Request $request): JsonResponse
    {
        /** @var Student|null $student */
        $student = auth::guard('students')->user();

        if (!$student) {
            return $this->returnError('User not authenticated', 401);
        }

        $fromDate = $request->query('from_date');
        $toDate   = $request->query('to_date');

        if (!$fromDate || !$toDate) {
            $now = Carbon::now();
            $fromDate = $now->copy()->startOfWeek()->toDateString();
            $toDate   = $now->copy()->endOfWeek()->toDateString();
        }

        $classroomId = $student->current_classroom_id ? (int) $student->current_classroom_id : null;
        $summary = StudentSummary::getWeeklySummary($student->id, $fromDate, $toDate, $classroomId);

        $this->setResult('summary', $summary);
        return $this->returnResponse();
    }

    public function monthlySummary(Request $request): JsonResponse
    {
        /** @var Student|null $student */
        $student = auth::guard('students')->user();

        if (!$student) {
            return $this->returnError('User not authenticated', 401);
        }

        $month = $request->query('month', Carbon::now()->format('Y-m'));

        $summary = StudentSummary::getMonthlySummary($student->id, $month);

        $this->setResult('summary', $summary);
        return $this->returnResponse();
    }
}
