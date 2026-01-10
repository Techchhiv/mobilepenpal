<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\School;
use App\Models\Teacher;
use Illuminate\Http\Request;
use Illuminate\Validation\Rules\Password;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        try {
            $data = $request->validate([
                'name'     => ['required', 'string', 'max:255'],
                'email'    => ['required', 'email', 'max:255', 'unique:users,email'],
                'password' => ['required', Password::min(8)],
            ]);

            $user = User::create([
                'name'     => $data['name'],
                'email'    => $data['email'],
                'password' => Hash::make($data['password']),
            ]);

            [$abilities, $permissionsPayload] = $this->abilitiesAndPerms($user);
            $token = $user->createToken('spa', $abilities)->plainTextToken;

            $payload = $user->load('roles')->toArray();
            $payload['permissions'] = $permissionsPayload;

            return response()->json([
                'message'   => 'Registered successfully',
                'token'     => $token,
                'user'      => $payload,
                'abilities' => $abilities,
            ], 201);
        } catch (\Throwable $e) {
            Log::error('REGISTER_ERROR', ['msg' => $e->getMessage()]);
            return response()->json(['message' => 'Server error during register.'], 500);
        }
    }

    public function login(Request $request)
    {
        try {
            $data = $request->validate([
                'email'      => ['required','email'],
                'password'   => ['required','min:6'],
                'school_key' => ['nullable','string'],
            ]);

            $user = User::where('email', $data['email'])->first();
            if (!$user || !Hash::check($data['password'], $user->password)) {
                return response()->json(['message' => 'Invalid credentials'], 422);
            }

            // If user is school-based, enforce school_key
            $roles = $user->roles->pluck('name')->toArray();
            if (collect($roles)->intersect(['school-admin','teacher','parent'])->isNotEmpty()) {
                if (empty($data['school_key'])) {
                    return response()->json(['message' => 'School key is required for school accounts'], 422);
                }
                $school = School::where('school_key', $data['school_key'])->first();
                if (!$school) {
                    return response()->json(['message' => 'Invalid school key'], 404);
                }
                if ((int)$user->school_id !== (int)$school->id) {
                    return response()->json(['message' => 'This user does not belong to that school'], 403);
                }
            }

            // Mark user (and linked teacher) online
            $this->markUserAndTeacherOnline($user);

            [$abilities, $permissionsPayload] = $this->abilitiesAndPerms($user);
            $token = $user->createToken('spa', $abilities)->plainTextToken;

            $payload = $user->load('roles')->toArray();
            $payload['permissions'] = $permissionsPayload;

            return response()->json([
                'token'     => $token,
                'user'      => $payload,
                'abilities' => $abilities,
            ]);
        } catch (\Throwable $e) {
            \Log::error('LOGIN_ERROR', ['msg' => $e->getMessage()]);
            return response()->json(['message' => 'Server error during login.'], 500);
        }
    }

    public function teacherLogin(Request $request)
    {
        $data = $request->validate([
            'teacher_id' => ['required','string'],
            'password'   => ['required','string'],
            'school_key' => ['required','string'],
        ]);

        // 1) Validate school
        $school = School::where('school_key', $data['school_key'])->first();
        if (!$school) {
            return response()->json(['message' => 'Invalid school key'], 422);
        }

        // 2) Find teacher (must be active & in that school)
        $teacher = Teacher::where('teacher_id', $data['teacher_id'])
            ->where('school_id', $school->id)
            ->where('is_active', 1)
            ->first();
        Log::info($teacher);
        if (!$teacher) {
            return response()->json(['message' => 'Teacher not found for this school, or inactive'], 422);
        }

        // 3) Authenticate via User (by email)
        $user = User::where('email', $teacher->email)->first();
        if (!$user || !Hash::check($data['password'], $user->password)) {
            return response()->json(['message' => 'Invalid credentials'], 422);
        }

        // Ensure link to this school (or enforce strictly by returning 403)
        if ((int)$user->school_id !== (int)$school->id) {
            $user->school_id = $school->id;
            $user->save();
        }

        // 4) Mark both online
        $this->markUserAndTeacherOnline($user, $teacher);

        // 5) Build abilities & token (same as normal login)
        [$abilities, $permissionsPayload] = $this->abilitiesAndPerms($user);
        $token = $user->createToken('spa', $abilities)->plainTextToken;

        $payload = $user->load('roles')->toArray();
        $payload['permissions'] = $permissionsPayload;

        return response()->json([
            'token'     => $token,
            'user'      => $payload,   // frontend expects `user`
            'abilities' => $abilities,
        ]);
    }

    public function me(Request $request)
    {
        $user = $request->user();

        [$abilities, $permissionsPayload] = $this->abilitiesAndPerms($user);

        $payload = $user->load('roles')->toArray();
        $payload['permissions'] = $permissionsPayload;

        return response()->json($payload);
    }

    public function logout(Request $request)
    {
        if ($user = $request->user()) {
            // delete current token only
            $user->currentAccessToken()?->delete();

            // if other tokens exist, keep online; else mark offline
            $stillOnline = $user->tokens()->exists();

            $user->forceFill([
                'is_online'    => $stillOnline,
                'last_seen_at' => now(),
            ])->save();

            // mirror to teacher (by email & school)
            Teacher::where('email', $user->email)
                ->when($user->school_id, fn($q) => $q->where('school_id', $user->school_id))
                ->update([
                    'is_online'    => $stillOnline,
                    'last_seen_at' => now(),
                ]);
        }

        return response()->json(['message' => 'Logged out']);
    }

    /**
     * Build abilities + permissions safely (works even if Spatie tables not migrated yet).
     */
    private function abilitiesAndPerms(User $user): array
    {
        $spatieTablesExist = Schema::hasTable('permissions')
            && Schema::hasTable('roles')
            && Schema::hasTable('model_has_roles')
            && Schema::hasTable('role_has_permissions');

        if ($spatieTablesExist) {
            $isSuper = $user->hasRole('super-admin');

            $permissions = $user->getAllPermissions()
                ->pluck('name')
                ->map(fn($p) => strtolower(str_replace(' ', '-', $p)))
                ->toArray();

            $abilities = $isSuper ? ['*'] : $permissions;

            return [$abilities, $permissions];
        }

        return [[], []];
    }

    /**
     * Helper: mark user and (optional) teacher online, update last_seen_at.
     */
    private function markUserAndTeacherOnline(User $user, ?Teacher $teacher = null): void
    {
        $now = now();

        $user->forceFill([
            'is_online'    => true,
            'last_seen_at' => $now,
        ])->save();

        if (!$teacher) {
            $teacher = Teacher::where('email', $user->email)
                ->when($user->school_id, fn($q) => $q->where('school_id', $user->school_id))
                ->first();
        }

        if ($teacher) {
            $teacher->forceFill([
                'is_online'    => true,
                'last_seen_at' => $now,
            ])->save();
        }
    }
}
