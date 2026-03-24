<?php

namespace App\Http\Controllers\Student\V01;

use App\Models\Student;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\JsonResponse;
use App\Http\Resources\Student\V01\User\UserDetailResource;

class ShopController extends Controller
{
    /**
     * Handle purchasing an avatar.
     * Deducts the cost from the student's coin balance and adds the avatar to unlocked_avatars.
     */
    public function purchaseAvatar(Request $request): JsonResponse
    {
        $request->validate([
            'avatar' => 'required|string',
            'cost' => 'required|integer|min:0',
        ]);

        /** @var Student $student */
        $student = Auth::user();

        if (!$student) {
            return $this->returnError(__('messages.user_not_authenticated'), 401);
        }

        $cost = (int)$request->cost;
        $avatarName = $request->avatar;

        if ($student->coin < $cost) {
            return $this->returnError(__('messages.not_enough_coins'), 400);
        }

        $unlockedAvatars = $student->unlocked_avatars ?? [];

        if (!in_array($avatarName, $unlockedAvatars)) {
            $unlockedAvatars[] = $avatarName;
        }

        $student->update([
            'coin' => max(0, $student->coin - $cost),
            'unlocked_avatars' => $unlockedAvatars,
        ]);

        $this->setResult('student', new UserDetailResource($student));

        return $this->returnResponse();
    }
}
