<?php

namespace App\Http\Controllers\School\V01;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;

class SchoolProfileController extends Controller
{
    /**
     * GET /school/profile
     * Returns the authenticated user profile with school details.
     */
    public function show(Request $request)
    {
        $user = $request->user();
        $user->load('roles');

        $school = null;
        if ($user->school_id) {
            $school = \App\Models\School::where('id', $user->school_id)
                ->withCount(['teachers', 'students', 'classrooms'])
                ->first();
        }

        return response()->json([
            'user' => [
                'id'         => $user->id,
                'name'       => $user->name,
                'email'      => $user->email,
                'phone'      => $user->phone ?? null,
                'photo'      => $user->photo ?? null,
                'school_id'  => $user->school_id,
                'is_online'  => $user->is_online,
                'roles'      => $user->roles->pluck('name'),
                'created_at' => $user->created_at,
            ],
            'school' => $school ? [
                'id'               => $school->id,
                'name'             => $school->name,
                'school_key'       => $school->school_key,
                'admin_email'      => $school->admin_email,
                'is_active'        => $school->is_active,
                'teachers_count'   => $school->teachers_count,
                'students_count'   => $school->students_count,
                'classrooms_count' => $school->classrooms_count,
            ] : null,
        ]);
    }

    /**
     * PUT /school/profile
     * Updates name, email, phone, and optionally password.
     */
    public function update(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'name'             => 'required|string|max:255',
            'email'            => 'required|email|max:255|unique:users,email,' . $user->id,
            'phone'            => 'nullable|string|max:30',
            'current_password' => 'nullable|string',
            'password'         => ['nullable', 'confirmed', Password::min(8)],
        ]);

        if (!empty($validated['password'])) {
            if (empty($validated['current_password']) || !Hash::check($validated['current_password'], $user->password)) {
                return response()->json([
                    'message' => 'Current password is incorrect.',
                    'errors'  => ['current_password' => ['Current password is incorrect.']],
                ], 422);
            }
        }

        $user->name  = $validated['name'];
        $user->email = $validated['email'];

        if (array_key_exists('phone', $validated)) {
            $user->phone = $validated['phone'];
        }

        if (!empty($validated['password'])) {
            $user->password = Hash::make($validated['password']);
        }

        $user->save();

        return response()->json([
            'message' => 'Profile updated successfully.',
            'user' => [
                'id'    => $user->id,
                'name'  => $user->name,
                'email' => $user->email,
                'phone' => $user->phone ?? null,
            ],
        ]);
    }
}
