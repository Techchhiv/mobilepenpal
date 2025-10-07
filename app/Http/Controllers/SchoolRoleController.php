<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;

class SchoolRoleController extends Controller
{
public function __construct()
{
    $this->middleware('auth:api');
   
}

    public function index(Request $request)
    {
        $authUser = $request->user();

        // School-admin sees only roles created for their school
        $query = Role::query()->with('permissions:id,name');

        if ($authUser->hasRole('school-admin')) {
            $query->where('school_id', $authUser->school_id);
        }

        $roles = $query->orderBy('name')->get();

        return response()->json($roles);
    }

    public function store(Request $request)
    {
        $authUser = $request->user();

        $request->validate([
            'name' => 'required|string|max:255|unique:roles,name',
            'permissions' => 'array',
            'permissions.*' => 'exists:permissions,name',
        ]);

        $role = new Role();
        $role->name = $request->name;
        $role->guard_name = 'api';

        if ($authUser->hasRole('school-admin')) {
            $role->school_id = $authUser->school_id;
        }

        $role->save();

        if ($request->has('permissions')) {
            $role->syncPermissions($request->permissions);
        }

        return response()->json($role->load('permissions'), 201);
    }

    public function show(Request $request, $id)
    {
        $authUser = $request->user();
        $role = Role::with('permissions:id,name')->findOrFail($id);

        if ($authUser->hasRole('school-admin') && $role->school_id !== $authUser->school_id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        return response()->json($role);
    }

    public function update(Request $request, $id)
    {
        $authUser = $request->user();
        $role = Role::findOrFail($id);

        if ($authUser->hasRole('school-admin') && $role->school_id !== $authUser->school_id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $request->validate([
            'name' => 'sometimes|required|string|max:255|unique:roles,name,' . $role->id,
            'permissions' => 'array',
            'permissions.*' => 'exists:permissions,name',
        ]);

        if ($request->has('name')) $role->name = $request->name;

        $role->save();

        if ($request->has('permissions')) {
            $role->syncPermissions($request->permissions);
        }

        return response()->json($role->load('permissions'));
    }

    public function destroy(Request $request, $id)
    {
        $authUser = $request->user();
        $role = Role::findOrFail($id);

        if ($authUser->hasRole('school-admin') && $role->school_id !== $authUser->school_id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $role->delete();
        return response()->json(null, 204);
    }
}
