<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;

class AdminRoleController extends Controller
{
   public function __construct()
{
    $this->middleware(['auth:api', 'role:super-admin,api']); // ✅ same guard
}


    public function index()
    {
        // include permissions on each role
        $roles = Role::with('permissions')->get();
        return response()->json($roles);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name'        => ['required','string','max:255','unique:roles,name'],
            'permissions' => ['array'],
            'permissions.*' => ['string','exists:permissions,name'],
        ]);

        $role = Role::create(['name' => $data['name']]);

        if (!empty($data['permissions'])) {
            $role->syncPermissions($data['permissions']);
        }

        return response()->json($role->load('permissions'), 201);
    }

    public function update(Request $request, Role $role)
    {
        $data = $request->validate([
            'name'        => ['sometimes','required','string','max:255','unique:roles,name,'.$role->id],
            'permissions' => ['array'],
            'permissions.*' => ['string','exists:permissions,name'],
        ]);

        if (isset($data['name'])) {
            $role->name = $data['name'];
            $role->save();
        }

        if (array_key_exists('permissions', $data)) {
            $role->syncPermissions($data['permissions'] ?? []);
        }

        return response()->json($role->load('permissions'));
    }

    public function destroy(Role $role)
    {
        // prevent deleting super-admin role
        if ($role->name === 'super-admin') {
            return response()->json(['message' => 'Cannot delete super-admin role'], 422);
        }
        $role->delete();
        return response()->json(null, 204);
    }
}
