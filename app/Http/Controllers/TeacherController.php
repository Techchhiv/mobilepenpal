<?php

namespace App\Http\Controllers;

use App\Models\Teacher;
use App\Models\User;
use App\Models\School;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\DB;

class TeacherController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth:api');
    }

    public function index()
    {
        $user = auth()->user();

        $teachers = Teacher::with('school')
            ->where('school_id', $user->school_id)
            ->orderByDesc('id')
            ->get();

        return response()->json($teachers);
    }

    public function store(Request $request)
    {
        $authUser = auth()->user();

        // Must belong to a school
        if (!$authUser->school_id) {
            return response()->json(['message' => 'You are not associated with a school.'], 403);
        }

        // Load the school so we can copy the real school_key
        $school = School::find($authUser->school_id);
        if (!$school) {
            return response()->json(['message' => 'School not found.'], 404);
        }

        $validator = Validator::make($request->all(), [
            'name'     => 'required|string|max:255',
            'email'    => 'required|email|unique:users,email',
            'phone'    => 'nullable|string|max:20',
            'subject'  => 'nullable|string|max:100',
            'photo'    => 'nullable|image|max:2048',
            'password' => 'required|string|min:6',
        ]);
        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        return DB::transaction(function () use ($request, $authUser, $school) {
            // Build teacher data
            $teacherData = $request->only(['name', 'email', 'phone', 'subject']);
            $teacherData['school_id']  = $authUser->school_id;
            $teacherData['school_key'] = $school->school_key; // ← use real school key

            // Unique teacher_id like TCH-XXXXXX
            do {
                $candidate = 'TCH-' . strtoupper(Str::random(6));
            } while (Teacher::where('teacher_id', $candidate)->exists());
            $teacherData['teacher_id'] = $candidate;

            if ($request->hasFile('photo')) {
                $teacherData['photo'] = $request->file('photo')->store('teachers', 'public');
            }

            $teacher = Teacher::create($teacherData);

            // Create matching user for login
            $userAccount = User::create([
                'name'      => $teacher->name,
                'email'     => $teacher->email,
                'password'  => Hash::make($request->password),
                'school_id' => $authUser->school_id,
            ]);
            $userAccount->assignRole('teacher');

            return response()->json([
                'teacher' => $teacher,
                'user'    => $userAccount,
            ], 201);
        });
    }

    public function show($id)
    {
        $teacher = Teacher::with('school')->find($id);
        if (!$teacher) {
            return response()->json(['message' => 'Teacher not found'], 404);
        }
        return response()->json($teacher);
    }

    public function update(Request $request, $id)
    {
        $teacher = Teacher::find($id);
        if (!$teacher) return response()->json(['message' => 'Teacher not found'], 404);

        // Find the linked user to craft the proper unique rule
        $linkedUser = User::where('email', $teacher->email)->first();

        $validator = Validator::make($request->all(), [
            'name'     => 'sometimes|required|string|max:255',
            // ignore the linked USER id (not teacher id)
            'email'    => 'sometimes|required|email|unique:users,email,' . optional($linkedUser)->id,
            'phone'    => 'nullable|string|max:20',
            'subject'  => 'nullable|string|max:100',
            'photo'    => 'nullable|image|max:2048',
            'password' => 'nullable|string|min:6',
        ]);
        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        return DB::transaction(function () use ($request, $teacher, $linkedUser) {
            $data = $request->only(['name', 'phone', 'subject']);

            // If email is changing, keep teacher.email in sync
            if ($request->filled('email')) {
                $data['email'] = $request->email;
            }

            if ($request->hasFile('photo')) {
                if ($teacher->photo && Storage::disk('public')->exists($teacher->photo)) {
                    Storage::disk('public')->delete($teacher->photo);
                }
                $data['photo'] = $request->file('photo')->store('teachers', 'public');
            }

            $teacher->update($data);

            // Sync login user
            if ($linkedUser) {
                $userData = [];
                if ($request->filled('name'))  $userData['name']  = $request->name;
                if ($request->filled('email')) $userData['email'] = $request->email;
                if ($request->filled('password')) $userData['password'] = Hash::make($request->password);

                if (!empty($userData)) $linkedUser->update($userData);
            }

            return response()->json($teacher);
        });
    }

    public function destroy($id)
    {
        $teacher = Teacher::find($id);
        if (!$teacher) return response()->json(['message' => 'Teacher not found'], 404);

        return DB::transaction(function () use ($teacher) {
            if ($teacher->photo && Storage::disk('public')->exists($teacher->photo)) {
                Storage::disk('public')->delete($teacher->photo);
            }

            // delete matching user (by email)
            if ($teacher->email) {
                $userAccount = User::where('email', $teacher->email)->first();
                if ($userAccount) $userAccount->delete();
            }

            $teacher->delete();

            return response()->json(['message' => 'Teacher deleted successfully']);
        });
    }
}
