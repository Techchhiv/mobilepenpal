<?php

namespace App\Http\Controllers;

use App\Models\Teacher;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Hash;

class TeacherController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth:api'); // only authenticated school-admin
    }

    /**
     * Display all teachers for this school.
     */
    public function index()
    {
        $user = auth()->user();
        $teachers = Teacher::with('school')
            ->where('school_id', $user->school_id)
            ->orderByDesc('id')
            ->get();
        return response()->json($teachers);
    }

    /**
     * Create a new teacher.
     */
    public function store(Request $request)
    {
        $user = auth()->user();

        // Ensure school admin
        if (!$user->school_id) {
            return response()->json(['message' => 'You are not associated with a school.'], 403);
        }

        $validator = Validator::make($request->all(), [
            'name'     => 'required|string|max:255',
            'email'    => 'required|email|unique:users,email', // store in users
            'phone'    => 'nullable|string|max:20',
            'subject'  => 'nullable|string|max:100',
            'photo'    => 'nullable|image|max:2048',
            'password' => 'required|string|min:6', // store in users
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        // 1️⃣ Create the teacher record in teachers table
        // 1️⃣ Create the teacher record in teachers table
        $teacherData = $request->only(['name', 'email', 'phone', 'subject']);
        $teacherData['school_id'] = $user->school_id;
        $teacherData['teacher_id'] = strtoupper('TCH-' . Str::random(6));
        $teacherData['school_key'] = strtoupper(Str::random(8));

        if ($request->hasFile('photo')) {
            $path = $request->file('photo')->store('teachers', 'public');
            $teacherData['photo'] = $path;
        }

        $teacher = Teacher::create($teacherData);


        // 2️⃣ Create corresponding user record for login
        $userData = [
            'name'      => $request->name,
            'email'     => $request->email,
            'password'  => Hash::make($request->password),
            'school_id' => $user->school_id,
        ];

        $userAccount = User::create($userData);
        $userAccount->assignRole('teacher');

        return response()->json([
            'teacher' => $teacher,
            'user'    => $userAccount
        ], 201);
    }

    /**
     * Show teacher details.
     */
    public function show($id)
    {
        $teacher = Teacher::with('school')->find($id);
        if (!$teacher) {
            return response()->json(['message' => 'Teacher not found'], 404);
        }
        return response()->json($teacher);
    }

    /**
     * Update teacher info.
     */
    public function update(Request $request, $id)
    {
        $teacher = Teacher::find($id);
        if (!$teacher) return response()->json(['message' => 'Teacher not found'], 404);

        $validator = Validator::make($request->all(), [
            'name'     => 'sometimes|required|string|max:255',
            'email'    => 'sometimes|required|email|unique:users,email,' . $teacher->id,
            'phone'    => 'nullable|string|max:20',
            'subject'  => 'nullable|string|max:100',
            'photo'    => 'nullable|image|max:2048',
            'password' => 'nullable|string|min:6',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $data = $request->only(['name', 'phone', 'subject']);

        if ($request->hasFile('photo')) {
            if ($teacher->photo && Storage::disk('public')->exists($teacher->photo)) {
                Storage::disk('public')->delete($teacher->photo);
            }
            $path = $request->file('photo')->store('teachers', 'public');
            $data['photo'] = $path;
        }

        $teacher->update($data);

        // Update corresponding user login
        $userAccount = User::where('email', $teacher->email)->first();
        if ($userAccount) {
            $userData = $request->only(['name', 'email']);
            if ($request->has('password')) {
                $userData['password'] = Hash::make($request->password);
            }
            $userAccount->update($userData);
        }

        return response()->json($teacher);
    }

    /**
     * Delete a teacher.
     */
    public function destroy($id)
    {
        $teacher = Teacher::find($id);
        if (!$teacher) return response()->json(['message' => 'Teacher not found'], 404);

        // Delete photo
        if ($teacher->photo && Storage::disk('public')->exists($teacher->photo)) {
            Storage::disk('public')->delete($teacher->photo);
        }

        // Delete corresponding user account
        $userAccount = User::where('email', $teacher->email)->first();
        if ($userAccount) $userAccount->delete();

        $teacher->delete();

        return response()->json(['message' => 'Teacher deleted successfully']);
    }
}
