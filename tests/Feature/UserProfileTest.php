<?php

namespace Tests\Feature;

use App\Models\School;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class UserProfileTest extends TestCase
{
    /**
     * Test unauthenticated access to /api/profile is rejected.
     */
    public function test_unauthenticated_user_cannot_access_profile(): void
    {
        $response = $this->getJson('/api/profile');
        $response->assertStatus(401);
    }

    /**
     * Test authenticated user can view their profile.
     */
    public function test_authenticated_user_can_view_profile(): void
    {
        $user = User::factory()->create([
            'name' => 'Test User',
            'email' => 'test_view_' . uniqid() . '@example.com',
        ]);

        try {
            Sanctum::actingAs($user, ['*'], 'api');

            $response = $this->getJson('/api/profile');
            $response->assertStatus(200)
                ->assertJsonStructure([
                    'user' => [
                        'id',
                        'name',
                        'email',
                        'roles',
                        'status',
                        'created_at',
                    ],
                    'school',
                ]);
        } finally {
            $user->delete();
        }
    }

    /**
     * Test authenticated user belonging to a school receives school information.
     */
    public function test_authenticated_user_with_school_can_view_school_info(): void
    {
        $school = School::create([
            'name' => 'Angkor High School',
            'admin_email' => 'angkor_admin_' . uniqid() . '@example.com',
            'is_active' => true,
        ]);

        $user = User::factory()->create([
            'name' => 'School Teacher',
            'email' => 'teacher_' . uniqid() . '@example.com',
            'school_id' => $school->id,
        ]);

        try {
            Sanctum::actingAs($user, ['*'], 'api');

            $response = $this->getJson('/api/profile');
            $response->assertStatus(200)
                ->assertJsonPath('school.id', $school->id)
                ->assertJsonPath('school.name', 'Angkor High School');
        } finally {
            $user->delete();
            $school->delete();
        }
    }

    /**
     * Test authenticated user can update their own name.
     */
    public function test_authenticated_user_can_update_profile_name(): void
    {
        $user = User::factory()->create([
            'name' => 'Original Name',
            'email' => 'test_update_' . uniqid() . '@example.com',
        ]);

        try {
            Sanctum::actingAs($user, ['*'], 'api');

            $response = $this->putJson('/api/profile', [
                'name' => 'Updated Name',
            ]);

            $response->assertStatus(200)
                ->assertJson([
                    'message' => 'Profile updated successfully.',
                    'user' => [
                        'name' => 'Updated Name',
                    ],
                ]);

            $this->assertEquals('Updated Name', $user->fresh()->name);
        } finally {
            $user->delete();
        }
    }

    /**
     * Test user cannot update sensitive fields such as role, school_id, or email.
     */
    public function test_user_cannot_update_role_or_school_via_profile(): void
    {
        $user = User::factory()->create([
            'name' => 'Safe User',
            'email' => 'test_safe_' . uniqid() . '@example.com',
            'school_id' => null,
        ]);

        try {
            Sanctum::actingAs($user, ['*'], 'api');

            $response = $this->putJson('/api/profile', [
                'name' => 'Safe User Renamed',
                'role' => 'Super Admin',
                'school_id' => 12345,
                'email' => 'hacked@example.com',
            ]);

            $response->assertStatus(200);
            $fresh = $user->fresh();
            $this->assertEquals('Safe User Renamed', $fresh->name);
            $this->assertNull($fresh->school_id);
            $this->assertNotEquals('hacked@example.com', $fresh->email);
        } finally {
            $user->delete();
        }
    }

    /**
     * Test password change requires valid current password and confirmed new password.
     */
    public function test_password_change_validation_and_success(): void
    {
        $user = User::factory()->create([
            'name' => 'Password Tester',
            'email' => 'test_pw_' . uniqid() . '@example.com',
            'password' => Hash::make('currentPassword123'),
        ]);

        try {
            Sanctum::actingAs($user, ['*'], 'api');

            // Wrong current password
            $failResponse = $this->putJson('/api/profile/password', [
                'current_password' => 'wrongPassword',
                'password' => 'newPassword123',
                'password_confirmation' => 'newPassword123',
            ]);
            $failResponse->assertStatus(422)
                ->assertJson([
                    'message' => 'Current password is incorrect.',
                ]);

            // Unconfirmed new password
            $unconfirmedResponse = $this->putJson('/api/profile/password', [
                'current_password' => 'currentPassword123',
                'password' => 'newPassword123',
                'password_confirmation' => 'mismatchPassword',
            ]);
            $unconfirmedResponse->assertStatus(400);

            // Valid password change
            $successResponse = $this->putJson('/api/profile/password', [
                'current_password' => 'currentPassword123',
                'password' => 'newPassword123',
                'password_confirmation' => 'newPassword123',
            ]);
            $successResponse->assertStatus(200)
                ->assertJson([
                    'message' => 'Password updated successfully.',
                ]);

            $this->assertTrue(Hash::check('newPassword123', $user->fresh()->password));
        } finally {
            $user->delete();
        }
    }

    /**
     * Test authenticated user can upload and remove photo.
     */
    public function test_authenticated_user_can_upload_and_remove_photo(): void
    {
        $user = User::factory()->create([
            'name' => 'Photo Tester',
            'email' => 'test_photo_' . uniqid() . '@example.com',
        ]);

        try {
            Sanctum::actingAs($user, ['*'], 'api');

            // Valid base64 png
            $sampleBase64 = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

            $uploadResponse = $this->putJson('/api/profile', [
                'name' => 'Photo Tester',
                'photo' => $sampleBase64,
            ]);

            $uploadResponse->assertStatus(200);
            $freshUser = $user->fresh();
            $this->assertNotNull($freshUser->photo);

            // Remove photo by passing empty string / null
            $removeResponse = $this->putJson('/api/profile', [
                'name' => 'Photo Tester',
                'photo' => '',
            ]);

            $removeResponse->assertStatus(200);
            $this->assertNull($user->fresh()->photo);
        } finally {
            $user->delete();
        }
    }
}
