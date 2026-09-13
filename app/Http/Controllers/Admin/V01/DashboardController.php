<?php

namespace App\Http\Controllers\Admin\V01;

use App\Http\Controllers\Controller;
use App\Models\Classroom;
use App\Models\Expense;
use App\Models\Invoice;
use App\Models\Payment;
use App\Models\School;
use App\Models\Student;
use App\Models\StudentExerciseAttempt;
use App\Models\Subscription;
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

        // Financial Summary Calculations with Periods
        $financialPeriod = $request->query('financial_period', 'all_time');
        $financialFrom = $request->query('financial_from');
        $financialTo = $request->query('financial_to');
        $now = Carbon::now();

        $paymentsQuery = Payment::where('status', 'completed');
        $expensesQuery = Expense::query();
        $label = 'All Time';

        if ($financialPeriod === 'today') {
            $paymentsQuery->whereDate('paid_at', $now->toDateString());
            $expensesQuery->whereDate('spent_at', $now->toDateString());
            $label = 'Today (' . $now->format('M d, Y') . ')';
        } elseif ($financialPeriod === 'this_month') {
            $paymentsQuery->whereMonth('paid_at', $now->month)->whereYear('paid_at', $now->year);
            $expensesQuery->whereMonth('spent_at', $now->month)->whereYear('spent_at', $now->year);
            $label = 'This Month (' . $now->format('F Y') . ')';
        } elseif ($financialPeriod === 'this_year') {
            $paymentsQuery->whereYear('paid_at', $now->year);
            $expensesQuery->whereYear('spent_at', $now->year);
            $label = 'This Year (' . $now->year . ')';
        } elseif ($financialPeriod === 'last_30_days') {
            $paymentsQuery->where('paid_at', '>=', $now->copy()->subDays(30));
            $expensesQuery->where('spent_at', '>=', $now->copy()->subDays(30)->toDateString());
            $label = 'Last 30 Days';
        } elseif ($financialFrom || $financialTo) {
            if ($financialFrom && $financialTo) {
                $paymentsQuery->whereBetween('paid_at', [$financialFrom . ' 00:00:00', $financialTo . ' 23:59:59']);
                $expensesQuery->whereBetween('spent_at', [$financialFrom, $financialTo]);
                $label = Carbon::parse($financialFrom)->format('M d, Y') . ' – ' . Carbon::parse($financialTo)->format('M d, Y');
            } elseif ($financialFrom) {
                $paymentsQuery->where('paid_at', '>=', $financialFrom . ' 00:00:00');
                $expensesQuery->where('spent_at', '>=', $financialFrom);
                $label = 'From ' . Carbon::parse($financialFrom)->format('M d, Y');
            } elseif ($financialTo) {
                $paymentsQuery->where('paid_at', '<=', $financialTo . ' 23:59:59');
                $expensesQuery->where('spent_at', '<=', $financialTo);
                $label = 'Up to ' . Carbon::parse($financialTo)->format('M d, Y');
            }
        }

        $totalRevenue = (float) $paymentsQuery->sum('amount');
        $totalExpenses = (float) $expensesQuery->sum('amount');
        $netProfit = round($totalRevenue - $totalExpenses, 2);

        // Precalculated Comparisons
        $allTimeRevenue = (float) Payment::where('status', 'completed')->sum('amount');
        $allTimeExpenses = (float) Expense::sum('amount');
        $allTimeProfit = round($allTimeRevenue - $allTimeExpenses, 2);

        $monthRevenue = (float) Payment::where('status', 'completed')->whereMonth('paid_at', $now->month)->whereYear('paid_at', $now->year)->sum('amount');
        $monthExpenses = (float) Expense::whereMonth('spent_at', $now->month)->whereYear('spent_at', $now->year)->sum('amount');
        $monthProfit = round($monthRevenue - $monthExpenses, 2);

        $yearRevenue = (float) Payment::where('status', 'completed')->whereYear('paid_at', $now->year)->sum('amount');
        $yearExpenses = (float) Expense::whereYear('spent_at', $now->year)->sum('amount');
        $yearProfit = round($yearRevenue - $yearExpenses, 2);

        $financialPayload = [
            'period'         => $financialPeriod,
            'period_label'   => $label,
            'total_revenue'  => round($totalRevenue, 2),
            'total_expenses' => round($totalExpenses, 2),
            'net_profit'     => $netProfit,
            'currency'       => 'USD',
            'as_of_date'     => $now->format('F d, Y - h:i A'),
            'breakdown'      => [
                'all_time' => [
                    'revenue'  => round($allTimeRevenue, 2),
                    'expenses' => round($allTimeExpenses, 2),
                    'profit'   => $allTimeProfit,
                    'label'    => 'All Time',
                ],
                'this_month' => [
                    'revenue'  => round($monthRevenue, 2),
                    'expenses' => round($monthExpenses, 2),
                    'profit'   => $monthProfit,
                    'label'    => 'This Month (' . $now->format('F Y') . ')',
                ],
                'this_year' => [
                    'revenue'  => round($yearRevenue, 2),
                    'expenses' => round($yearExpenses, 2),
                    'profit'   => $yearProfit,
                    'label'    => 'This Year (' . $now->year . ')',
                ],
            ]
        ];

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
                    'financial' => $financialPayload,
                ],
                'financial_summary' => $financialPayload,
                'practice_trend' => $practiceTrend,
                'top_schools' => $topSchools,
                'expiring_subscriptions' => $expiringSubscriptions,
                'recent_activities' => $recentActivities,
            ]
        ]);
    }

    /**
     * Get summary counts for Needs Attention section on Admin Dashboard
     */
    public function needsAttention(Request $request)
    {
        $now = Carbon::now();

        // 1. Subscriptions expiring within the next 30 days
        $expiringSubscriptions = Subscription::where('active', true)
            ->whereBetween('end_date', [$now->copy()->startOfDay(), $now->copy()->addDays(30)->endOfDay()])
            ->count();

        // 2. Unpaid or pending invoices
        $unpaidInvoices = Invoice::whereIn('status', ['unpaid', 'pending'])->count();

        // 3. Failed payments
        $failedPayments = Payment::where('status', 'failed')->count();

        return response()->json([
            'success' => true,
            'data' => [
                'expiring_subscriptions' => $expiringSubscriptions,
                'unpaid_invoices'        => $unpaidInvoices,
                'failed_payments'        => $failedPayments,
            ],
        ]);
    }
}
