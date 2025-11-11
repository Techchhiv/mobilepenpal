<?php

namespace App\Http\Controllers\Student\V01;

use App\Http\Requests\Student\V01\User\UpdateUserRequest;
use App\Http\Resources\Student\V01\User\UserDetailResource;
use App\Models\Student;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Symfony\Component\HttpFoundation\JsonResponse;

class UserController extends Controller
{
    public function profile(): JsonResponse
    {
        $authUser = Auth::user();

        if (!$authUser) {
            return $this->returnError('User not authenticated', 401);
        }

        $this->setResult("profile", new UserDetailResource($authUser));
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
}
