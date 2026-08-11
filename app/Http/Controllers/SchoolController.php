<?php

namespace App\Http\Controllers;

use App\Models\School;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use App\Services\AuditService;

class SchoolController extends Controller
{
  public function __construct()
{
    $this->middleware('auth:api')->except(['publicList']);
   
}

    public function index()
    {
        $schools = School::with('admin:id,name,email')
            ->select(['id','name','slug','school_key','admin_email','is_active','created_at'])
            ->orderByDesc('id')
            ->paginate(15);

        return response()->json($schools);
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255|unique:schools,name',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|string|min:8',
            'school_key' => 'required|string|unique:schools,school_key',
        ]);

        $school = School::create([
            'name'       => $request->name,
            'slug'       => Str::slug($request->name),
            'school_key' => $request->school_key,
            'admin_email'=> $request->email,
        ]);

        $user = User::create([
            'name'      => $request->name . ' Admin',
            'email'     => $request->email,
            'password'  => Hash::make($request->password),
            'school_id' => $school->id,
        ]);

        $user->assignRole('school-admin');

        AuditService::record(
            action: 'school.created',
            target: $school,
            new: ['name' => $school->name, 'school_key' => '[REDACTED]', 'admin_email' => $school->admin_email],
            description: "School created: {$school->name}",
            severity: 'info'
        );

        return response()->json([
            'message' => 'School created successfully',
            'school'  => $school,
            'admin'   => $user,
        ], 201);
    }

    public function show(School $school)
    {
        return response()->json($school->load('admin'));
    }

    public function update(Request $request, School $school)
    {
        $request->validate([
            'name' => 'sometimes|required|string|max:255|unique:schools,name,' . $school->id,
            'is_active' => 'boolean',
        ]);

        // Track what changed
        $oldValues = ['name' => $school->getOriginal('name'), 'is_active' => $school->getOriginal('is_active')];

        if ($request->has('name')) {
            $school->name = $request->name;
            $school->slug = Str::slug($request->name);
        }

        if ($request->has('is_active')) {
            $school->is_active = $request->boolean('is_active');
        }

        $school->save();
        $newValues = ['name' => $school->name, 'is_active' => $school->is_active];

        $action   = ($oldValues['is_active'] !== $newValues['is_active']) ? 'school.status.changed' : 'school.updated';
        $severity = ($action === 'school.status.changed') ? 'warning' : 'info';

        AuditService::record(
            action: $action,
            target: $school,
            old: $oldValues,
            new: $newValues,
            description: "School updated: {$school->name}",
            severity: $severity
        );

        return response()->json([
            'message' => 'School updated',
            'school'  => $school,
        ]);
    }

    public function destroy(School $school)
    {
        $snapshot = ['name' => $school->name, 'admin_email' => $school->admin_email, 'is_active' => $school->is_active];

        AuditService::record(
            action: 'school.deleted',
            target: $school,
            old: $snapshot,
            description: "School deleted: {$school->name}",
            severity: 'warning',
            metadata: $snapshot
        );

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

    // Public endpoint for student registration
    public function publicList()
    {
        $schools = School::where('is_active', true)
            ->select(['id', 'name', 'school_key'])
            ->orderBy('name')
            ->get();

        return response()->json([
            'data' => $schools
        ]);
    }
}
