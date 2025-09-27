<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Spatie\Permission\Models\Permission;

class SchoolPermissionController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth:api');
        $this->middleware('permission:permissions.manage');
    }

    public function index(Request $request)
    {
        $authUser = $request->user();

        $query = Permission::query();

        if ($authUser->hasRole('school-admin')) {
            $query->where('school_id', $authUser->school_id);
        }

        $perms = $query->orderBy('name')->get();

        return response()->json($perms);
    }

    public function store(Request $request)
    {
        $authUser = $request->user();

        $request->validate([
            'name' => 'required|string|max:255|unique:permissions,name',
        ]);

        $perm = new Permission();
        $perm->name = $request->name;
        $perm->guard_name = 'api';

        if ($authUser->hasRole('school-admin')) {
            $perm->school_id = $authUser->school_id;
        }

        $perm->save();

        return response()->json($perm, 201);
    }

    public function show(Request $request, $id)
    {
        $authUser = $request->user();
        $perm = Permission::findOrFail($id);

        if ($authUser->hasRole('school-admin') && $perm->school_id !== $authUser->school_id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        return response()->json($perm);
    }

    public function update(Request $request, $id)
    {
        $authUser = $request->user();
        $perm = Permission::findOrFail($id);

        if ($authUser->hasRole('school-admin') && $perm->school_id !== $authUser->school_id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $request->validate([
            'name' => 'required|string|max:255|unique:permissions,name,' . $perm->id,
        ]);

        $perm->name = $request->name;
        $perm->save();

        return response()->json($perm);
    }

    public function destroy(Request $request, $id)
    {
        $authUser = $request->user();
        $perm = Permission::findOrFail($id);

        if ($authUser->hasRole('school-admin') && $perm->school_id !== $authUser->school_id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $perm->delete();
        return response()->json(null, 204);
    }
}
