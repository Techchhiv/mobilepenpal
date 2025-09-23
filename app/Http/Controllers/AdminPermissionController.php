<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Spatie\Permission\Models\Permission;

class AdminPermissionController extends Controller
{
    public function __construct()
{
    $this->middleware(['auth:api', 'role:super-admin,api']); // ✅ same guard
}


    public function index()
    {
        return response()->json(Permission::all());
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => ['required','string','max:255','unique:permissions,name'],
        ]);

        $perm = Permission::create(['name' => $data['name']]);
        return response()->json($perm, 201);
    }

    public function update(Request $request, Permission $permission)
    {
        $data = $request->validate([
            'name' => ['required','string','max:255','unique:permissions,name,'.$permission->id],
        ]);

        $permission->name = $data['name'];
        $permission->save();

        return response()->json($permission);
    }

    public function destroy(Permission $permission)
    {
        $permission->delete();
        return response()->json(null, 204);
    }
}
