<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Spatie\Permission\Models\Role;


class SchoolUserController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth:api');
    }

    /**
     * Display a listing of school users.
     */
    public function index(Request $request)
    {
        $authUser = $request->user();

        // Only school-admin: see users in their school
        $query = User::query()->with('roles:id,name');

        if ($authUser) {
            $query->where('id', '!=', $authUser->id);

            if ($authUser->hasRole('school-admin')) {
                $query->where('school_id', $authUser->school_id);
            }
        }

        $users = $query->select(['id', 'name', 'email', 'created_at'])
            ->orderByDesc('id')
            ->paginate(15);

        $users->getCollection()->transform(function ($u) {
            $u->permissions = $u->getAllPermissions()->pluck('name')->values();
            return $u;
        });

        return response()->json($users);
    }

    /**
     * Store a newly created school user.
     */
    // App/Http/Controllers/SchoolUserController.php


    // ...

    public function store(Request $request)
    {
        $authUser = $request->user();

        $request->validate([
            'name'     => 'required|string|max:255',
            'email'    => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:8',
            'roles'    => 'array',
            'roles.*'  => 'exists:roles,name',
        ]);

        $user = User::create([
            'name'      => $request->name,
            'email'     => $request->email,
            'password'  => Hash::make($request->password),
            'school_id' => $authUser->hasRole('school-admin') ? $authUser->school_id : null,
        ]);

        $roles = $request->input('roles', []);

        // If school-admin is selected, auto-add all per-school roles
        if (in_array('school-admin', $roles, true) && $user->school_id) {
            $tenantRoleNames = Role::where('school_id', $user->school_id)->pluck('name')->all();
            $roles = array_values(array_unique(array_merge($roles, $tenantRoleNames)));
        }

        if (!empty($roles)) {
            $user->syncRoles($roles);
        }

        return response()->json($user->load('roles'), 201);
    }



    /**
     * Display a specific school user.
     */
    public function show(Request $request, $id)
    {
        $authUser = $request->user();
        $user = User::with('roles:id,name')->findOrFail($id);

        if ($authUser->hasRole('school-admin') && $user->school_id !== $authUser->school_id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $user->permissions = $user->getAllPermissions()->pluck('name')->values();
        return response()->json($user);
    }

    /**
     * Update a specific school user.
     */
    public function update(Request $request, $id)
    {
        $authUser = $request->user();
        $user = User::findOrFail($id);

        if ($authUser && (int)$user->id === (int)$authUser->id) {
            return response()->json(['message' => 'You cannot modify your own account from user management.'], 403);
        }

        if ($authUser->hasRole('school-admin') && $user->school_id !== $authUser->school_id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $request->validate([
            'name'     => 'sometimes|required|string|max:255',
            'email'    => 'sometimes|required|string|email|max:255|unique:users,email,' . $user->id,
            'password' => 'sometimes|nullable|string|min:8',
            'roles'    => 'array',
            'roles.*'  => 'exists:roles,name',
        ]);

        $user->fill([
            'name'  => $request->input('name', $user->name),
            'email' => $request->input('email', $user->email),
        ]);

        if ($request->filled('password')) {
            $user->password = Hash::make($request->password);
        }
        $user->save();

        if ($request->has('roles')) {
            $roles = $request->input('roles', []);

            if (in_array('school-admin', $roles, true) && $user->school_id) {
                $tenantRoleNames = Role::where('school_id', $user->school_id)->pluck('name')->all();
                $roles = array_values(array_unique(array_merge($roles, $tenantRoleNames)));
            }

            $user->syncRoles($roles);
        }

        return response()->json($user->load('roles'));
    }

    /**
     * Remove a school user.
     */
    public function destroy(Request $request, $id)
    {
        $authUser = $request->user();
        $user = User::findOrFail($id);

        if ($authUser && (int)$user->id === (int)$authUser->id) {
            return response()->json(['message' => 'You cannot delete your own account.'], 403);
        }

        if ($authUser->hasRole('school-admin') && $user->school_id !== $authUser->school_id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $user->delete();
        return response()->json(null, 204);
    }
}
