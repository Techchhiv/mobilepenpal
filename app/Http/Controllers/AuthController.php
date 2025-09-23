<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Validation\Rules\Password;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema; // 👈 add this

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
            'email'    => ['required','email'],
            'password' => ['required','min:6'],
        ]);

        $user = User::where('email', $data['email'])->first();

        if (!$user || !Hash::check($data['password'], $user->password)) {
            return response()->json(['message' => 'Invalid credentials'], 422);
        }

        // Default abilities
        $abilities = [];
        $permissionsPayload = collect();

        // Only touch Spatie if tables exist
        $spatieOk = Schema::hasTable('permissions')
            && Schema::hasTable('roles')
            && Schema::hasTable('model_has_roles')
            && Schema::hasTable('role_has_permissions');

        if ($spatieOk) {
            $abilities = $user->hasRole('super-admin')
                ? ['*']
                : $user->getAllPermissions()->pluck('name')->toArray();

            $permissionsPayload = $user->getAllPermissions()->pluck('name');
        }

        // If Sanctum table missing, this line will still throw → migrate
        $token = $user->createToken('spa', $abilities)->plainTextToken;

        $payload = $user->load('roles')->toArray();
        $payload['permissions'] = $permissionsPayload;

        return response()->json([
            'token'     => $token,
            'user'      => $payload,
            'abilities' => $abilities,
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
        // If Spatie tables don’t exist yet, avoid querying them.
        $spatieTablesExist = Schema::hasTable('permissions')
            && Schema::hasTable('roles')
            && Schema::hasTable('model_has_roles')
            && Schema::hasTable('role_has_permissions');

        if ($spatieTablesExist) {
            $isSuper = $user->hasRole('super-admin');
            $abilities = $isSuper ? ['*'] : $user->getAllPermissions()->pluck('name')->toArray();
            $permissionsPayload = $user->getAllPermissions()->pluck('name');
        } else {
            // Safe defaults until migrations are in place
            $abilities = [];
            $permissionsPayload = collect();
        }

        return [$abilities, $permissionsPayload];
    }
}
