<?php

namespace App\Http\Controllers;

use App\Models\Teacher;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Hash;

class TeacherController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth:api');
    }

    /**
     * Display a listing of teachers.
     */
    public function index()
    {
        $teachers = Teacher::with('school')->orderBy('id', 'desc')->get();
        return response()->json($teachers);
    }

    /**
     * Store a newly created teacher.
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'school_id' => 'required|exists:schools,id',
            'name'      => 'required|string|max:255',
            'email'     => 'required|email|unique:teachers,email',
            'phone'     => 'nullable|string|max:20',
            'subject'   => 'nullable|string|max:100',
            'photo'     => 'nullable|image|max:2048', // max 2MB
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $data = $request->only(['school_id', 'name', 'email', 'phone', 'subject']);

        if ($request->hasFile('photo')) {
            $path = $request->file('photo')->store('teachers', 'public');
            $data['photo'] = $path;
        }

        // Generate teacher login ID, school key, and password
        $data['teacher_id'] = strtoupper('TCH-'.Str::random(6));
        $data['school_key'] = strtoupper(Str::random(8));
        $data['password'] = Hash::make(Str::random(8)); // random password

        $teacher = Teacher::create($data);

        return response()->json($teacher, 201);
    }

    /**
     * Display the specified teacher.
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
     * Update the specified teacher.
     */
    public function update(Request $request, $id)
    {
        $teacher = Teacher::find($id);
        if (!$teacher) {
            return response()->json(['message' => 'Teacher not found'], 404);
        }

        $validator = Validator::make($request->all(), [
            'school_id' => 'sometimes|required|exists:schools,id',
            'name'      => 'sometimes|required|string|max:255',
            'email'     => 'sometimes|required|email|unique:teachers,email,' . $teacher->id,
            'phone'     => 'nullable|string|max:20',
            'subject'   => 'nullable|string|max:100',
            'photo'     => 'nullable|image|max:2048',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $data = $request->only(['school_id', 'name', 'email', 'phone', 'subject']);

        if ($request->hasFile('photo')) {
            // Delete old photo if exists
            if ($teacher->photo && Storage::disk('public')->exists($teacher->photo)) {
                Storage::disk('public')->delete($teacher->photo);
            }
            $path = $request->file('photo')->store('teachers', 'public');
            $data['photo'] = $path;
        }

        $teacher->update($data);

        return response()->json($teacher);
    }

    /**
     * Remove the specified teacher.
     */
    public function destroy($id)
    {
        $teacher = Teacher::find($id);
        if (!$teacher) {
            return response()->json(['message' => 'Teacher not found'], 404);
        }

        // Delete photo if exists
        if ($teacher->photo && Storage::disk('public')->exists($teacher->photo)) {
            Storage::disk('public')->delete($teacher->photo);
        }

        $teacher->delete();

        return response()->json(['message' => 'Teacher deleted successfully']);
    }
}
