<?php

namespace App\Http\Controllers\School\V01;

use App\Http\Controllers\Controller;
use App\Models\Student;
use App\Models\Subscription;
use App\Models\Teacher;
use Carbon\Carbon;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    /**
     * Return dashboard metrics for the authenticated school.
     */
    public function index(Request $request)
    {
        $user = $request->user();
        $schoolId = $user->school_id;

        if (!$schoolId) {
            return response()->json([
                'success' => false,
                'message' => 'No school associated with this account.',
            ], 403);
        }

        $now = Carbon::now();

        // Counts
        $totalStudents = Student::where('school_id', $schoolId)->count();
        $totalTeachers = Teacher::where('school_id', $schoolId)->count();

        // Total exercise attempts across all students in the school
        $studentIds = Student::where('school_id', $schoolId)->pluck('id');
        $totalExerciseAttempts = \App\Models\StudentExerciseAttempt::whereIn('student_id', $studentIds)->count();

        // Active subscription
        $activeSubscription = Subscription::where('school_id', $schoolId)
            ->where('active', true)
            ->where('start_date', '<=', $now)
            ->where('end_date', '>=', $now)
            ->orderBy('end_date', 'desc')
            ->first();

        $subscriptionData = null;
        if ($activeSubscription) {
            $subscriptionData = [
                'is_active' => true,
                'plan' => $activeSubscription->plan,
                'end_date' => $activeSubscription->end_date->toDateString(),
                'days_left' => (int) $now->diffInDays($activeSubscription->end_date, false),
            ];
        } else {
            $subscriptionData = [
                'is_active' => false,
                'plan' => null,
                'end_date' => null,
                'days_left' => 0,
            ];
        }

        return response()->json([
            'success' => true,
            'data' => [
                'total_students' => $totalStudents,
                'total_teachers' => $totalTeachers,
                'total_exercise_attempts' => $totalExerciseAttempts,
                'subscription' => $subscriptionData,
            ],
        ]);
    }
}
