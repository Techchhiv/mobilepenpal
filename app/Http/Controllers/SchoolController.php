<?php

namespace App\Http\Controllers;

use App\Models\School;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Spatie\Permission\Models\Role;

class SchoolController extends Controller
{
    public function __construct()
    {
        $this->middleware(['auth:api', 'role:super-admin,api']);
    }

    /**
     * Display a listing of schools.
     */
    public function index()
    {
        $schools = School::with('admin:id,name,email') // eager load school admin
            ->select(['id','name','slug','school_key','admin_email','is_active','created_at'])
            ->orderByDesc('id')
            ->paginate(15);

        return response()->json($schools);
    }

    /**
     * Store a new school and its admin.
     */
public function store(Request $request)
{
    $request->validate([
        'name' => 'required|string|max:255|unique:schools,name',
        'email' => 'required|email|unique:users,email',
        'password' => 'required|string|min:8',
        'school_key' => 'required|string|unique:schools,school_key',
    ]);

    // Create school
    $school = School::create([
        'name'       => $request->name,
        'slug'       => Str::slug($request->name),
        'school_key' => $request->school_key,
        'admin_email'=> $request->email,
    ]);

    // Create school admin user
    $user = User::create([
        'name'      => $request->name . ' Admin',
        'email'     => $request->email,
        'password'  => Hash::make($request->password),
        'school_id' => $school->id,
    ]);

    $user->assignRole('school-admin');

    return response()->json([
        'message' => 'School created successfully',
        'school'  => $school,
        'admin'   => $user,
    ], 201);
}


    /**
     * Show details of a school.
     */
    public function show(School $school)
    {
        return response()->json($school->load('admin'));
    }

    /**
     * Update school info.
     */
    public function update(Request $request, School $school)
    {
        $request->validate([
            'school_name'  => 'sometimes|required|string|max:255|unique:schools,name,' . $school->id,
            'is_active'    => 'boolean',
        ]);

        if ($request->has('school_name')) {
            $school->name = $request->school_name;
            $school->slug = Str::slug($request->school_name);
        }

        if ($request->has('is_active')) {
            $school->is_active = $request->boolean('is_active');
        }

        $school->save();

        return response()->json([
            'message' => 'School updated',
            'school'  => $school,
        ]);
    }

    /**
     * Delete a school (and its users).
     */
    public function destroy(School $school)
    {
        $school->delete();

        return response()->json([
            'message' => 'School deleted'
        ], 200);
    }

    public function generateKey()
{
    do {
        $key = 'SCH-' . strtoupper(Str::random(6));
    } while (School::where('school_key', $key)->exists());

    return response()->json(['key' => $key]);
}

}
