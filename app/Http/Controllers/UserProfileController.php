<?php

namespace App\Http\Controllers;

use App\Helpers\UploadMedia;
use App\Models\School;
use App\Services\AuditService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rules\Password;

class UserProfileController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth:api');
    }

    /**
     * GET /api/profile
     * Return authenticated user details, roles, and school (if applicable).
     */
    public function show(Request $request)
    {
        $user = $request->user();
        $user->load(['roles', 'school']);

        $school = $user->school;

        return response()->json([
            'user' => [
                'id'         => $user->id,
                'name'       => $user->name,
                'email'      => $user->email,
                'photo'      => $user->photo ?? null,
                'roles'      => $user->roles->pluck('name'),
                'school_id'  => $user->school_id,
                'is_online'  => (bool) $user->is_online,
                'status'     => 'Active',
                'created_at' => $user->created_at,
                'updated_at' => $user->updated_at,
            ],
            'school' => $school ? [
                'id'          => $school->id,
                'name'        => $school->name,
                'school_key'  => $school->school_key,
                'admin_email' => $school->admin_email,
                'is_active'   => (bool) $school->is_active,
            ] : null,
        ]);
    }

    /**
     * PUT /api/profile
     * Update safe personal profile information (name, photo).
     * Sensitive administrative fields (roles, permissions, school, status) are strictly immutable.
     */
    public function update(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'name'  => ['required', 'string', 'max:255'],
            'photo' => ['nullable'],
        ]);

        $oldName = $user->name;
        $user->name = $validated['name'];

        // Handle profile photo upload / removal if key was provided
        if ($request->hasFile('photo')) {
            $request->validate([
                'photo' => ['image', 'mimes:jpeg,png,jpg,webp', 'max:2048'],
            ]);

            $this->removeExistingPhoto($user);
            $user->photo = UploadMedia::uploadImageFile($request->file('photo'));
        } elseif ($request->has('photo')) {
            $photoInput = $request->input('photo');

            if (empty($photoInput)) {
                // Remove photo
                $this->removeExistingPhoto($user);
                $user->photo = null;
            } elseif (is_string($photoInput) && preg_match('/^data:image\/(png|jpe?g|webp);base64,/i', $photoInput)) {
                // Base64 upload
                $this->removeExistingPhoto($user);
                $path = UploadMedia::uploadImageBase64($photoInput);
                if ($path) {
                    $user->photo = $path;
                }
            }
        }

        $user->save();

        AuditService::record(
            action: 'account.profile.updated',
            target: $user,
            old: ['name' => $oldName],
            new: ['name' => $user->name, 'photo' => $user->photo],
            description: "User {$user->name} updated their profile",
            severity: 'info'
        );

        $user->load('roles');

        return response()->json([
            'message' => 'Profile updated successfully.',
            'user'    => [
                'id'         => $user->id,
                'name'       => $user->name,
                'email'      => $user->email,
                'photo'      => $user->photo ?? null,
                'roles'      => $user->roles->pluck('name'),
                'school_id'  => $user->school_id,
                'is_online'  => (bool) $user->is_online,
                'status'     => 'Active',
                'created_at' => $user->created_at,
            ],
        ]);
    }

    /**
     * PUT /api/profile/password
     * Change user password after verifying current password.
     */
    public function updatePassword(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'current_password' => ['required', 'string'],
            'password'         => ['required', 'confirmed', Password::min(8)],
        ]);

        if (!Hash::check($validated['current_password'], $user->password)) {
            return response()->json([
                'message' => 'Current password is incorrect.',
                'errors'  => [
                    'current_password' => ['Current password is incorrect.'],
                ],
            ], 422);
        }

        $user->password = Hash::make($validated['password']);
        $user->save();

        AuditService::record(
            action: 'account.password.updated',
            target: $user,
            description: "User {$user->name} changed their password",
            severity: 'info'
        );

        return response()->json([
            'message' => 'Password updated successfully.',
        ]);
    }

    /**
     * Helper to safely remove an old photo from disk.
     */
    private function removeExistingPhoto($user): void
    {
        if (!empty($user->photo)) {
            $relativePath = ltrim($user->photo, '/');
            $fullPath = public_path($relativePath);
            if (file_exists($fullPath)) {
                @unlink($fullPath);
            }
        }
    }
}
