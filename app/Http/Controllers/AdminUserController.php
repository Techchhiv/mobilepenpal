<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Services\AuditService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Spatie\Permission\Models\Role;

class AdminUserController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth:api');
    }

    /**
     * Display a listing of the resource.
     */
    public function index(Request $request)
    {
        $authUser = $request->user();

        $users = User::query()
            ->when($authUser, function ($q) use ($authUser) {
                $q->where('id', '!=', $authUser->id);
            })
            ->select(['id', 'name', 'email', 'is_online', 'last_seen_at', 'created_at'])
            ->with(['roles:id,name'])
            ->orderByDesc('id')
            ->paginate(15);

        $users->getCollection()->transform(function ($u) {
            $u->permissions = $u->getAllPermissions()->pluck('name')->values();
            return $u;
        });

        return response()->json($users);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $request->validate([
            'name'    => 'required|string|max:255',
            'email'   => 'required|string|email|max:255|unique:users',
            'password'=> 'required|string|min:8',
            'roles'   => 'array',
            'roles.*' => 'exists:roles,name',
        ]);

        $user = User::create([
            'name'     => $request->name,
            'email'    => $request->email,
            'password' => Hash::make($request->password),
        ]);

        if ($request->has('roles')) {
            $user->assignRole($request->roles);
        }

        AuditService::record(
            action: 'account.user.created',
            target: $user,
            new: ['name' => $user->name, 'email' => $user->email, 'roles' => $request->roles ?? []],
            description: "Admin user created: {$user->name} ({$user->email})",
            severity: 'info'
        );

        return response()->json($user->load('roles'), 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(User $user)
    {
        return response()->json($user->load('roles'));
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, User $user)
    {
        $authUser = $request->user();
        if ($authUser && (int)$user->id === (int)$authUser->id) {
            return response()->json(['message' => 'You cannot modify your own account from user management.'], 403);
        }

        $request->validate([
            'name'    => 'sometimes|required|string|max:255',
            'email'   => 'sometimes|required|string|email|max:255|unique:users,email,' . $user->id,
            'password'=> 'sometimes|nullable|string|min:8',
            'roles'   => 'array',
            'roles.*' => 'exists:roles,name',
        ]);

        // Snapshot before state for diff
        $oldRoles   = $user->roles->pluck('name')->toArray();
        $oldValues  = ['name' => $user->name, 'email' => $user->email, 'roles' => $oldRoles];
        $passwordChanged = false;

        $user->name  = $request->input('name', $user->name);
        $user->email = $request->input('email', $user->email);

        if ($request->filled('password')) {
            $user->password    = Hash::make($request->password);
            $passwordChanged   = true;
        }

        $user->save();

        $newRoles = $oldRoles;
        if ($request->has('roles')) {
            $user->syncRoles($request->roles);
            $newRoles = $request->roles;
        }

        $newValues = ['name' => $user->name, 'email' => $user->email, 'roles' => $newRoles];
        if ($passwordChanged) {
            $newValues['password_changed'] = true;
        }

        // Detect role change for warning severity
        $rolesChanged = $oldRoles !== $newRoles;
        $severity     = ($rolesChanged || $passwordChanged) ? 'warning' : 'info';
        $action       = 'account.user.updated';

        if ($rolesChanged) {
            AuditService::record(
                action: 'account.role.changed',
                target: $user,
                old: ['roles' => $oldRoles],
                new: ['roles' => $newRoles],
                description: "Role changed for user {$user->name} ({$user->email})",
                severity: 'warning'
            );
        }

        if ($passwordChanged) {
            AuditService::record(
                action: 'account.password.changed',
                target: $user,
                new: ['password_changed' => true],
                description: "Password changed for user {$user->name} ({$user->email}) by admin",
                severity: 'warning'
            );
        }

        AuditService::record(
            action: $action,
            target: $user,
            old: $oldValues,
            new: $newValues,
            description: "Admin user updated: {$user->name} ({$user->email})",
            severity: $severity
        );

        return response()->json($user->load('roles'));
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Request $request, User $user)
    {
        $authUser = $request->user();
        if ($authUser && (int)$user->id === (int)$authUser->id) {
            return response()->json(['message' => 'You cannot delete your own account.'], 403);
        }

        // Snapshot before deletion so audit record is meaningful after the user is gone
        $snapshot = [
            'name'  => $user->name,
            'email' => $user->email,
            'roles' => $user->roles->pluck('name')->toArray(),
        ];

        AuditService::record(
            action: 'account.user.deleted',
            target: $user,
            old: $snapshot,
            description: "Admin user deleted: {$user->name} ({$user->email})",
            severity: 'warning',
            metadata: $snapshot
        );

        $user->delete();

        return response()->json(null, 204);
    }
}