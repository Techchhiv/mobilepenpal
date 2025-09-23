<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\School;
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
                'name'     => ['required','string','max:255'],
                'email'    => ['required','email','max:255','unique:users,email'],
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
                'school_key' => ['nullable','string'], // ✅ school key optional
            ]);

            // if school_key is provided → restrict login to that school
            $school = null;
            if (!empty($data['school_key'])) {
                $school = School::where('school_key', $data['school_key'])->first();
                if (!$school) {
                    return response()->json(['message' => 'Invalid school key'], 404);
                }

                $user = User::where('email', $data['email'])
                    ->where('school_id', $school->id)
                    ->first();
            } else {
                // super admin login (no school key)
                $user = User::where('email', $data['email'])->first();
            }

            if (!$user || !Hash::check($data['password'], $user->password)) {
                return response()->json(['message' => 'Invalid credentials'], 422);
            }

            // Abilities & permissions
            [$abilities, $permissionsPayload] = $this->abilitiesAndPerms($user);

            $token = $user->createToken('spa', $abilities)->plainTextToken;

            $payload = $user->load('roles')->toArray();
            $payload['permissions'] = $permissionsPayload;

            return response()->json([
                'token'     => $token,
                'user'      => $payload,
                'abilities' => $abilities,
                'school'    => $school, // include school info if applicable
            ]);
        } catch (\Throwable $e) {
            Log::error('LOGIN_ERROR', ['msg' => $e->getMessage()]);
            return response()->json(['message' => 'Server error during login.'], 500);
        }
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
        $request->user()->currentAccessToken()?->delete();
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
            $abilities = $isSuper ? ['*'] : $user->getAllPermissions()->pluck('name')->toArray();
            $permissionsPayload = $user->getAllPermissions()->pluck('name');
        } else {
            $abilities = [];
            $permissionsPayload = collect();
        }

        return [$abilities, $permissionsPayload];
    }
}
