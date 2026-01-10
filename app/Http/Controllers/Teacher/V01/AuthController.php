<?php

namespace App\Http\Controllers\Teacher\V01;

use App\Http\Requests\Teacher\V01\RegisterRequest;
use App\Models\Branch;
use App\Models\School;
use App\Models\Teacher;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    public function login(Request $request)
    {
        $data = $request->validate([
            'teacher_id' => ['required', 'string'],
            'password'   => ['required', 'string'],
            'school_key' => ['required', 'string'],
        ]);

        $school = School::query()
            ->where('school_key', $data['school_key'])
            ->where('is_active', true)
            ->first();

        if (!$school) {
            return $this->returnError('Invalid school key.', 422);
        }

        $teacher = Teacher::query()
            ->where('teacher_id', $data['teacher_id'])
            ->with(['branch:id,school_id,branch_name,branch_code,is_active'])
            ->whereHas('branch', function ($q) use ($school) {
                $q->where('school_id', $school->id);
            })
            ->first();

        if (!$teacher || !Hash::check($data['password'], (string) $teacher->password)) {
            return $this->returnError('The provided credentials are incorrect.', 401);
        }

        if (!$teacher->is_active) {
            return $this->returnError('Your account is inactive. Please contact the administrator.', 403);
        }

        if (!$teacher->branch || !$teacher->branch->is_active) {
            return $this->returnError('Your branch is inactive. Please contact the administrator.', 403);
        }

        [$abilities, $permissionsPayload] = $this->abilitiesAndPerms($teacher);

        $teacher->tokens()->delete();

        $token = $teacher->createToken('teachers', $abilities)->plainTextToken;

        $payload = $teacher->load('branch')->toArray();
        $payload['permissions'] = $permissionsPayload;

        $this->setResult('teacher', $payload);
        $this->setResult('token', $token);
        $this->setResult('abilities', $abilities);

        return $this->returnResponse();
    }

    private function abilitiesAndPerms(Teacher $teacher): array
    {
        $spatieTablesExist = Schema::hasTable('permissions')
            && Schema::hasTable('roles')
            && Schema::hasTable('model_has_roles')
            && Schema::hasTable('role_has_permissions');

        if ($spatieTablesExist) {
            // If you plan a super role for teachers, keep this. Otherwise you can remove.
            $isSuper = method_exists($teacher, 'hasRole') && $teacher->hasRole('super-admin');

            $permissions = $teacher->getAllPermissions()
                ->pluck('name')
                ->map(fn ($p) => strtolower(str_replace(' ', '-', $p)))
                ->values()
                ->toArray();

            $abilities = $isSuper ? ['*'] : $permissions;

            return [$abilities, $permissions];
        }

        // fallback if spatie tables aren't ready
        return [['teacher'], ['teacher']];
    }

    public function register(RegisterRequest $request)
    {
        $branch = Branch::with('school')
            ->where('id', $request->branch_id)
            ->where('is_active', true)
            ->first();

        if (!$branch) {
            return $this->returnError('Branch not found or inactive.', 422);
        }

        if (!$branch->school || !$branch->school->is_active) {
            return $this->returnError('School is inactive or not found.', 403);
        }

        $teacherId = $this->generateUniqueTeacherId($branch->branch_code);

        $teacher = Teacher::create([
            'branch_id'  => $branch->id,
            'teacher_id' => $teacherId,

            'name'       => $request->name,
            'email'      => $request->email,
            'password'   => Hash::make($request->password),

            'phone'      => $request->phone,
            'subject'    => $request->subject,
            'is_active'  => true,
        ]);

        $token = $teacher->createToken('teachers')->plainTextToken;

        $this->setResult('teacher', $teacher);
        $this->setResult('token', $token);

        return $this->returnResponse();
    }


    public function me(Request $request)
    {
        $this->setResult("teacher", $request->user());
        return $this->returnResponse();
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return $this->returnSuccess("ok");
    }

    private function generateUniqueTeacherId(string $branchCode): string
    {
        $year = now()->format('Y');
        $prefix = $branchCode . $year;

        $lastId = Teacher::where('teacher_id', 'like', $prefix . '%')
            ->orderBy('teacher_id', 'desc')
            ->value('teacher_id');

        $nextNumber = 1;

        if ($lastId) {
            $lastNumber = (int) substr($lastId, -4);
            $nextNumber = $lastNumber + 1;
        }

        do {
            $teacherId = $prefix . str_pad((string) $nextNumber, 4, '0', STR_PAD_LEFT);
            $nextNumber++;
        } while (Teacher::where('teacher_id', $teacherId)->exists());

        return $teacherId;
    }
}
