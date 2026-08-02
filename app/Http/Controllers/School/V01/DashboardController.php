<?php

namespace App\Http\Controllers\School\V01;

use App\Http\Controllers\Controller;
use App\Models\Classroom;
use App\Models\ClassroomEnrollment;
use App\Models\School;
use App\Models\Student;
use App\Models\Subscription;
use App\Models\Teacher;
use App\Models\StudentExerciseAttempt;
use Carbon\Carbon;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    /**
     * Return expanded dashboard metrics for the authenticated school or teacher.
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
        $school = School::select('id', 'admin_email')->find($schoolId);
        $userEmail = strtolower(trim((string) $user->email));
        $adminEmail = strtolower(trim((string) ($school->admin_email ?? '')));

        // Check if user is linked to a Teacher record
        $teacher = Teacher::where('school_id', $schoolId)
            ->whereRaw('LOWER(email) = ?', [$userEmail])
            ->first();

        $isSchoolAdmin = ($adminEmail && $userEmail === $adminEmail) || $user->hasRole('school-admin') || $user->hasRole('super-admin');

        // If user is a teacher and NOT super/school admin, render Teacher Dashboard View
        if ($teacher && !$isSchoolAdmin) {
            return $this->teacherDashboard($user, $schoolId, $teacher, $now);
        }

        // Otherwise render full School Admin Dashboard View
        return $this->schoolAdminDashboard($schoolId, $now);
    }

    /**
     * Teacher-Scoped Dashboard Data
     */
    private function teacherDashboard($user, $schoolId, Teacher $teacher, Carbon $now)
    {
        // 1. Teacher's Classrooms
        $teacherClassrooms = Classroom::where('school_id', $schoolId)
            ->where('teacher_id', $teacher->id)
            ->withCount([
                'enrollments as students_count' => function ($q) {
                    $q->where('status', 'enrolled');
                }
            ])
            ->orderByDesc('is_active')
            ->get();

        $teacherClassroomIds = $teacherClassrooms->pluck('id');

        // Enrolled Student IDs in teacher's classrooms
        $teacherStudentIds = ClassroomEnrollment::whereIn('classroom_id', $teacherClassroomIds)
            ->where('status', 'enrolled')
            ->pluck('student_id')
            ->unique()
            ->values();

        // 2. Metrics for Teacher's Students
        $totalStudents = $teacherStudentIds->count();
        $totalClassrooms = $teacherClassrooms->count();
        $activeClassrooms = $teacherClassrooms->where('is_active', true)->count();

        $totalAttempts = StudentExerciseAttempt::whereIn('student_id', $teacherStudentIds)->count();
        $correctAttempts = StudentExerciseAttempt::whereIn('student_id', $teacherStudentIds)->where('is_correct', true)->count();
        $avgAccuracy = $totalAttempts > 0 ? round(($correctAttempts / $totalAttempts) * 100, 1) : 0;

        $sevenDaysAgo = Carbon::now()->subDays(7);
        $activeStudents7d = StudentExerciseAttempt::whereIn('student_id', $teacherStudentIds)
            ->where('created_at', '>=', $sevenDaysAgo)
            ->distinct('student_id')
            ->count('student_id');

        // 3. Daily Practice Trend (last 14 days)
        $fourteenDaysAgo = Carbon::now()->subDays(13)->startOfDay();
        $rawTrend = StudentExerciseAttempt::whereIn('student_id', $teacherStudentIds)
            ->where('created_at', '>=', $fourteenDaysAgo)
            ->selectRaw('DATE(created_at) as date, COUNT(*) as attempts, SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END) as correct')
            ->groupBy('date')
            ->orderBy('date', 'asc')
            ->get()
            ->keyBy('date');

        $dailyTrend = [];
        for ($i = 13; $i >= 0; $i--) {
            $d = Carbon::now()->subDays($i)->toDateString();
            $item = $rawTrend->get($d);
            $dailyTrend[] = [
                'date' => $d,
                'label' => Carbon::parse($d)->format('M d'),
                'attempts' => $item ? (int)$item->attempts : 0,
                'correct' => $item ? (int)$item->correct : 0,
            ];
        }

        // 4. Classroom Performance Comparison
        $classroomComparison = $teacherClassrooms->map(function ($c) {
            $enrolledStudentIds = ClassroomEnrollment::where('classroom_id', $c->id)
                ->where('status', 'enrolled')
                ->pluck('student_id');

            $attempts = StudentExerciseAttempt::whereIn('student_id', $enrolledStudentIds)->count();
            $correct = StudentExerciseAttempt::whereIn('student_id', $enrolledStudentIds)->where('is_correct', true)->count();
            $acc = $attempts > 0 ? round(($correct / $attempts) * 100, 1) : 0;

            return [
                'id' => $c->id,
                'name' => $c->name,
                'join_code' => $c->join_code,
                'students_count' => $c->students_count,
                'total_attempts' => $attempts,
                'accuracy' => $acc,
                'is_active' => (bool)$c->is_active,
            ];
        });

        // 5. Students Needing Attention (Accuracy < 65% or 0 practice)
        $studentsNeedingAttention = [];
        foreach ($teacherStudentIds as $stId) {
            $st = Student::select('id', 'first_name', 'last_name', 'nickname', 'avatar')->find($stId);
            if (!$st) continue;

            $stAttempts = StudentExerciseAttempt::where('student_id', $stId)->count();
            $stCorrect = StudentExerciseAttempt::where('student_id', $stId)->where('is_correct', true)->count();
            $stAcc = $stAttempts > 0 ? round(($stCorrect / $stAttempts) * 100) : 0;

            $enr = ClassroomEnrollment::whereIn('classroom_id', $teacherClassroomIds)
                ->where('student_id', $stId)
                ->where('status', 'enrolled')
                ->first();

            $cr = $enr ? Classroom::find($enr->classroom_id) : null;

            if ($stAttempts === 0 || $stAcc < 65) {
                $studentsNeedingAttention[] = [
                    'student_id' => $st->id,
                    'student_name' => trim("{$st->first_name} {$st->last_name}") ?: $st->nickname ?: "Student #{$st->id}",
                    'avatar' => $st->avatar,
                    'classroom_id' => $cr ? $cr->id : null,
                    'classroom_name' => $cr ? $cr->name : 'Classroom',
                    'total_attempts' => $stAttempts,
                    'accuracy' => $stAcc,
                    'status' => $stAttempts === 0 ? 'No Practice' : 'Low Accuracy',
                ];
            }

            if (count($studentsNeedingAttention) >= 6) break;
        }

        // 6. Recent Activity Log
        $recentActivity = StudentExerciseAttempt::whereIn('student_id', $teacherStudentIds)
            ->with('exercise')
            ->orderByDesc('id')
            ->take(8)
            ->get()
            ->map(function ($att) {
                $st = Student::select('id', 'first_name', 'last_name', 'nickname')->find($att->student_id);
                $stName = $st ? (trim("{$st->first_name} {$st->last_name}") ?: $st->nickname ?: "Student #{$att->student_id}") : "Student #{$att->student_id}";

                $ex = $att->exercise;
                $exTitle = $ex ? ($ex->character ?: $ex->prompt ?: $ex->question ?: "Exercise #{$att->exercise_id}") : "Exercise Attempt";

                return [
                    'id' => $att->id,
                    'student_name' => $stName,
                    'exercise_title' => $exTitle,
                    'is_correct' => (bool)$att->is_correct,
                    'created_at' => $att->created_at ? $att->created_at->diffForHumans() : 'Just now',
                ];
            });

        return response()->json([
            'success' => true,
            'data' => [
                'is_teacher_view' => true,
                'teacher_name' => $teacher->name,
                'total_students' => $totalStudents,
                'active_students_7d' => $activeStudents7d,
                'total_teachers' => 1,
                'total_classrooms' => $totalClassrooms,
                'active_classrooms' => $activeClassrooms,
                'total_exercise_attempts' => $totalAttempts,
                'average_accuracy' => $avgAccuracy,
                'daily_trend' => $dailyTrend,
                'classroom_comparison' => $classroomComparison,
                'students_needing_attention' => $studentsNeedingAttention,
                'recent_activity' => $recentActivity,
                'subscription' => null,
            ],
        ]);
    }

    /**
     * School Admin Dashboard Data
     */
    private function schoolAdminDashboard($schoolId, Carbon $now)
    {
        $totalStudents = Student::where('school_id', $schoolId)->count();
        $totalTeachers = Teacher::where('school_id', $schoolId)->count();
        $totalClassrooms = Classroom::where('school_id', $schoolId)->count();
        $activeClassrooms = Classroom::where('school_id', $schoolId)->where('is_active', true)->count();

        $studentIds = Student::where('school_id', $schoolId)->pluck('id');

        $totalAttempts = StudentExerciseAttempt::whereIn('student_id', $studentIds)->count();
        $correctAttempts = StudentExerciseAttempt::whereIn('student_id', $studentIds)->where('is_correct', true)->count();
        $avgAccuracy = $totalAttempts > 0 ? round(($correctAttempts / $totalAttempts) * 100, 1) : 0;

        $sevenDaysAgo = Carbon::now()->subDays(7);
        $activeStudents7d = StudentExerciseAttempt::whereIn('student_id', $studentIds)
            ->where('created_at', '>=', $sevenDaysAgo)
            ->distinct('student_id')
            ->count('student_id');

        $fourteenDaysAgo = Carbon::now()->subDays(13)->startOfDay();
        $rawTrend = StudentExerciseAttempt::whereIn('student_id', $studentIds)
            ->where('created_at', '>=', $fourteenDaysAgo)
            ->selectRaw('DATE(created_at) as date, COUNT(*) as attempts, SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END) as correct')
            ->groupBy('date')
            ->orderBy('date', 'asc')
            ->get()
            ->keyBy('date');

        $dailyTrend = [];
        for ($i = 13; $i >= 0; $i--) {
            $d = Carbon::now()->subDays($i)->toDateString();
            $item = $rawTrend->get($d);
            $dailyTrend[] = [
                'date' => $d,
                'label' => Carbon::parse($d)->format('M d'),
                'attempts' => $item ? (int)$item->attempts : 0,
                'correct' => $item ? (int)$item->correct : 0,
            ];
        }

        $topClassrooms = Classroom::where('school_id', $schoolId)
            ->with(['teacher:id,name'])
            ->withCount([
                'enrollments as students_count' => function ($q) {
                    $q->where('status', 'enrolled');
                }
            ])
            ->take(5)
            ->get()
            ->map(function ($c) {
                return [
                    'id' => $c->id,
                    'name' => $c->name,
                    'teacher_name' => $c->teacher->name ?? '—',
                    'students_count' => $c->students_count,
                    'is_active' => (bool)$c->is_active,
                ];
            });

        $recentActivity = StudentExerciseAttempt::whereIn('student_id', $studentIds)
            ->with('exercise')
            ->orderByDesc('id')
            ->take(8)
            ->get()
            ->map(function ($att) {
                $st = Student::select('id', 'first_name', 'last_name', 'nickname')->find($att->student_id);
                $stName = $st ? (trim("{$st->first_name} {$st->last_name}") ?: $st->nickname ?: "Student #{$att->student_id}") : "Student #{$att->student_id}";

                $ex = $att->exercise;
                $exTitle = $ex ? ($ex->character ?: $ex->prompt ?: $ex->question ?: "Exercise #{$att->exercise_id}") : "Exercise Attempt";

                return [
                    'id' => $att->id,
                    'student_name' => $stName,
                    'exercise_title' => $exTitle,
                    'is_correct' => (bool)$att->is_correct,
                    'created_at' => $att->created_at ? $att->created_at->diffForHumans() : 'Just now',
                ];
            });

        $activeSubscription = Subscription::where('school_id', $schoolId)
            ->where('active', true)
            ->where('start_date', '<=', $now)
            ->where('end_date', '>=', $now)
            ->orderBy('end_date', 'desc')
            ->first();

        $subscriptionData = $activeSubscription ? [
            'is_active' => true,
            'plan' => $activeSubscription->plan,
            'end_date' => $activeSubscription->end_date->toDateString(),
            'days_left' => (int) $now->diffInDays($activeSubscription->end_date, false),
        ] : [
            'is_active' => false,
            'plan' => null,
            'end_date' => null,
            'days_left' => 0,
        ];

        return response()->json([
            'success' => true,
            'data' => [
                'is_teacher_view' => false,
                'total_students' => $totalStudents,
                'active_students_7d' => $activeStudents7d,
                'total_teachers' => $totalTeachers,
                'total_classrooms' => $totalClassrooms,
                'active_classrooms' => $activeClassrooms,
                'total_exercise_attempts' => $totalAttempts,
                'average_accuracy' => $avgAccuracy,
                'daily_trend' => $dailyTrend,
                'top_classrooms' => $topClassrooms,
                'recent_activity' => $recentActivity,
                'subscription' => $subscriptionData,
            ],
        ]);
    }
}
