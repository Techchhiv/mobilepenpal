<?php

namespace App\Http\Controllers\Admin\V01;

use App\Http\Controllers\Controller;
use App\Models\Classroom;
use App\Models\School;
use App\Models\Student;
use App\Models\StudentExerciseAttempt;
use App\Models\Teacher;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

class DashboardController extends Controller
{
    public function index(Request $request)
    {
        $totalSchools = School::count();
        $activeSchools = School::where('is_active', true)->count();
        $totalStudents = Student::count();
        $totalTeachers = Teacher::count();
        $totalClassrooms = Classroom::count();

        // 7-day active students
        $activeStudents7d = StudentExerciseAttempt::where('created_at', '>=', now()->subDays(7))
            ->distinct('student_id')
            ->count('student_id');

        // Platform-wide accuracy
        $totalAttemptsCount = StudentExerciseAttempt::count();
        $correctAttemptsCount = StudentExerciseAttempt::where('is_correct', true)->count();
        $platformAccuracy = $totalAttemptsCount > 0 ? round(($correctAttemptsCount / $totalAttemptsCount) * 100) : 0;

        // 14-Day Practice Volume & Accuracy Trend
        $practiceTrend = [];
        for ($i = 13; $i >= 0; $i--) {
            $dateStr = now()->subDays($i)->format('Y-m-d');
            $startOfDay = Carbon::parse($dateStr)->startOfDay();
            $endOfDay = Carbon::parse($dateStr)->endOfDay();

            $dayTotal = StudentExerciseAttempt::whereBetween('created_at', [$startOfDay, $endOfDay])->count();
            $dayCorrect = StudentExerciseAttempt::whereBetween('created_at', [$startOfDay, $endOfDay])
                ->where('is_correct', true)
                ->count();

            $practiceTrend[] = [
                'date' => $dateStr,
                'label' => Carbon::parse($dateStr)->format('M d'),
                'attempts' => $dayTotal,
                'correct' => $dayCorrect,
                'accuracy' => $dayTotal > 0 ? round(($dayCorrect / $dayTotal) * 100) : 0,
            ];
        }

        // Top Schools Overview
        $topSchools = School::withCount(['students', 'teachers', 'classrooms'])
            ->orderBy('students_count', 'desc')
            ->take(5)
            ->get()
            ->map(function ($school) {
                return [
                    'id' => $school->id,
                    'name' => $school->name,
                    'is_active' => (bool) $school->is_active,
                    'admin_email' => $school->admin_email,
                    'students_count' => $school->students_count,
                    'teachers_count' => $school->teachers_count,
                    'classrooms_count' => $school->classrooms_count,
                ];
            });

        // Expiring or Active Subscriptions
        $expiringSubscriptions = School::where('is_active', true)
            ->orderBy('created_at', 'desc')
            ->take(5)
            ->get(['id', 'name', 'is_active', 'created_at']);

        // Recent Platform Activities
        $recentActivities = StudentExerciseAttempt::with(['student:id,first_name,last_name,nickname', 'exercise'])
            ->orderByDesc('created_at')
            ->take(8)
            ->get()
            ->map(function ($attempt) {
                $studentName = $attempt->student ? ($attempt->student->nickname ?: $attempt->student->first_name) : 'Student';
                $exerciseTitle = $attempt->exercise ? ($attempt->exercise->character ?? $attempt->exercise->prompt ?? 'Exercise') : 'Exercise';

                return [
                    'id' => $attempt->id,
                    'student_name' => $studentName,
                    'exercise_title' => $exerciseTitle,
                    'is_correct' => (bool) $attempt->is_correct,
                    'time_ago' => $attempt->created_at ? $attempt->created_at->diffForHumans() : 'Just now',
                ];
            });

        return response()->json([
            'success' => true,
            'data' => [
                'summary' => [
                    'total_schools' => $totalSchools,
                    'active_schools' => $activeSchools,
                    'total_students' => $totalStudents,
                    'active_students_7d' => $activeStudents7d,
                    'total_teachers' => $totalTeachers,
                    'total_classrooms' => $totalClassrooms,
                    'platform_accuracy' => $platformAccuracy,
                ],
                'practice_trend' => $practiceTrend,
                'top_schools' => $topSchools,
                'expiring_subscriptions' => $expiringSubscriptions,
                'recent_activities' => $recentActivities,
            ]
        ]);
    }
}
