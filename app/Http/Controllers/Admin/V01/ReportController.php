<?php

namespace App\Http\Controllers\Admin\V01;

use App\Models\Expense;
use App\Models\Payment;
use App\Models\School;
use App\Models\Student;
use App\Models\Subscription;
use App\Models\Teacher;
use Carbon\Carbon;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\StreamedResponse;

class ReportController extends Controller
{
    public function index(Request $request)
    {
        $filters = $request->validate([
            'search' => 'nullable|string|max:255',
            'school_status' => 'nullable|in:active,inactive',
            'subscription_status' => 'nullable|in:active,scheduled,expired,inactive,none',
            'plan' => 'nullable|in:monthly,yearly',
            'financial_period' => 'nullable|in:all_time,this_month,this_year,last_30_days,today',
            'financial_from' => 'nullable|date',
            'financial_to' => 'nullable|date',
            'sort_by' => 'nullable|in:name,created_at,students_count,teachers_count,active_students_count,active_teachers_count',
            'sort_direction' => 'nullable|in:asc,desc',
            'per_page' => 'nullable|integer|min:1|max:100',
        ]);

        $today = Carbon::today();
        $perPage = (int) ($filters['per_page'] ?? 15);
        $sortBy = $filters['sort_by'] ?? 'created_at';
        $sortDirection = $filters['sort_direction'] ?? ($sortBy === 'name' ? 'asc' : 'desc');

        $query = $this->buildSchoolReportQuery();
        $this->applyFilters($query, $filters, $today);
        $this->applySorting($query, $sortBy, $sortDirection);

        $paginator = $query->paginate($perPage)->appends($request->query());
        $schools = $paginator->getCollection()
            ->map(fn(School $school) => $this->transformSchoolListItem($school, $today))
            ->values();

        $financialPeriod = $request->query('financial_period', 'all_time');
        $financialFrom = $request->query('financial_from');
        $financialTo = $request->query('financial_to');

        return $this->returnSuccess('School reports fetched successfully', [
            'summary' => $this->buildSummary($today, $financialPeriod, $financialFrom, $financialTo),
            'financial_summary' => $this->buildFinancialSummary($financialPeriod, $financialFrom, $financialTo),
            'top_schools' => $this->buildTopSchools(),
            'schools' => $schools,
            'filters' => [
                'search' => $filters['search'] ?? null,
                'school_status' => $filters['school_status'] ?? null,
                'subscription_status' => $filters['subscription_status'] ?? null,
                'plan' => $filters['plan'] ?? null,
                'sort_by' => $sortBy,
                'sort_direction' => $sortDirection,
                'per_page' => $perPage,
            ],
            'pagination' => [
                'current_page' => $paginator->currentPage(),
                'last_page' => $paginator->lastPage(),
                'per_page' => $paginator->perPage(),
                'total' => $paginator->total(),
                'from' => $paginator->firstItem(),
                'to' => $paginator->lastItem(),
            ],
        ]);
    }

    public function show(School $school)
    {
        $today = Carbon::today();

        $school->load([
            'admin:id,school_id,name,email',
            'subscriptions' => function ($query) {
                $query->orderByDesc('end_date')->orderByDesc('id');
            },
        ])->loadCount([
            'students',
            'students as active_students_count' => function ($query) {
                $query->where('is_active', true);
            },
            'students as male_students_count' => function ($query) {
                $query->where('gender', 'male');
            },
            'students as female_students_count' => function ($query) {
                $query->where('gender', 'female');
            },
            'teachers',
            'teachers as active_teachers_count' => function ($query) {
                $query->where('is_active', true);
            },
            'users',
            'branches',
            'subscriptions',
        ]);

        return $this->returnSuccess('School report fetched successfully', [
            'school' => $this->transformSchoolDetail($school, $today),
        ]);
    }

    public function export(Request $request): StreamedResponse
    {
        $filters = $request->validate([
            'search'              => 'nullable|string|max:255',
            'school_status'       => 'nullable|in:active,inactive',
            'subscription_status' => 'nullable|in:active,scheduled,expired,inactive,none',
            'plan'                => 'nullable|in:monthly,yearly',
            'financial_period'    => 'nullable|in:all_time,this_month,this_year,last_30_days,today',
            'financial_from'      => 'nullable|date',
            'financial_to'        => 'nullable|date',
            'sort_by'             => 'nullable|in:name,created_at,students_count,teachers_count,active_students_count,active_teachers_count',
            'sort_direction'      => 'nullable|in:asc,desc',
        ]);

        $today         = Carbon::today();
        $sortBy        = $filters['sort_by'] ?? 'created_at';
        $sortDirection = $filters['sort_direction'] ?? ($sortBy === 'name' ? 'asc' : 'desc');

        $query = $this->buildSchoolReportQuery();
        $this->applyFilters($query, $filters, $today);
        $this->applySorting($query, $sortBy, $sortDirection);

        $filename = 'school-report-' . now()->format('Y-m-d') . '.csv';

        return new StreamedResponse(function () use ($query, $today) {
            $handle = fopen('php://output', 'w');

            // UTF-8 BOM for Excel compatibility
            fwrite($handle, "\xEF\xBB\xBF");

            // Header row
            fputcsv($handle, [
                'School Name', 'School Key', 'Admin Email', 'School Status',
                'Total Students', 'Active Students',
                'Total Teachers', 'Active Teachers',
                'Plan', 'Subscription Status',
                'Sub Start', 'Sub End',
                'Created At', 'Last Updated At',
            ]);

            // Stream in chunks to avoid loading everything into memory
            $query->chunk(200, function ($schools) use ($handle, $today) {
                foreach ($schools as $school) {
                    $row = $this->transformSchoolListItem($school, $today);
                    fputcsv($handle, [
                        $row['name'],
                        $row['school_key'],
                        $row['admin_email'],
                        $row['status'],
                        $row['students_count'],
                        $row['active_students_count'],
                        $row['teachers_count'],
                        $row['active_teachers_count'],
                        $row['subscription_plan'] ?? '',
                        $row['subscription_status'] ?? '',
                        $row['subscription_start_date'] ?? '',
                        $row['subscription_end_date'] ?? '',
                        $row['created_at'] ? Carbon::parse($row['created_at'])->format('Y-m-d H:i') : '',
                        $row['updated_at'] ? Carbon::parse($row['updated_at'])->format('Y-m-d H:i') : '',
                    ]);
                }
            });

            fclose($handle);
        }, 200, [
            'Content-Type'        => 'text/csv; charset=UTF-8',
            'Content-Disposition' => 'attachment; filename="' . $filename . '"',
            'Cache-Control'       => 'no-cache, no-store, must-revalidate',
            'Pragma'              => 'no-cache',
            'Expires'             => '0',
        ]);
    }


    protected function buildSchoolReportQuery(): Builder
    {
        return School::query()
            ->select([
                'id',
                'name',
                'slug',
                'school_key',
                'admin_email',
                'is_active',
                'created_at',
                'updated_at',
            ])
            ->with([
                'admin:id,school_id,name,email',
                'subscriptions' => function ($query) {
                    $query->orderByDesc('end_date')->orderByDesc('id');
                },
            ])
            ->withCount([
                'students',
                'students as active_students_count' => function ($query) {
                    $query->where('is_active', true);
                },
                'teachers',
                'teachers as active_teachers_count' => function ($query) {
                    $query->where('is_active', true);
                },
            ]);
    }

    protected function applyFilters(Builder $query, array $filters, Carbon $today): void
    {
        $todayString = $today->toDateString();

        if (!empty($filters['search'])) {
            $search = trim($filters['search']);

            $query->where(function (Builder $builder) use ($search) {
                $builder
                    ->where('name', 'like', "%{$search}%")
                    ->orWhere('school_key', 'like', "%{$search}%")
                    ->orWhere('admin_email', 'like', "%{$search}%");
            });
        }

        if (!empty($filters['school_status'])) {
            $query->where('is_active', $filters['school_status'] === 'active');
        }

        if (!empty($filters['plan'])) {
            $query->whereHas('subscriptions', function (Builder $builder) use ($filters) {
                $builder->where('plan', $filters['plan']);
            });
        }

        if (empty($filters['subscription_status'])) {
            return;
        }

        switch ($filters['subscription_status']) {
            case 'active':
                $query->whereHas('subscriptions', function (Builder $builder) use ($todayString) {
                    $this->applyCurrentSubscriptionScope($builder, $todayString);
                });
                break;

            case 'scheduled':
                $query->whereHas('subscriptions', function (Builder $builder) use ($todayString) {
                    $builder
                        ->where('active', true)
                        ->whereDate('start_date', '>', $todayString);
                });
                break;

            case 'expired':
                $query
                    ->whereDoesntHave('subscriptions', function (Builder $builder) use ($todayString) {
                        $this->applyCurrentSubscriptionScope($builder, $todayString);
                    })
                    ->whereHas('subscriptions', function (Builder $builder) use ($todayString) {
                        $builder->whereDate('end_date', '<', $todayString);
                    });
                break;

            case 'inactive':
                $query
                    ->whereDoesntHave('subscriptions', function (Builder $builder) use ($todayString) {
                        $this->applyCurrentSubscriptionScope($builder, $todayString);
                    })
                    ->whereHas('subscriptions', function (Builder $builder) {
                        $builder->where('active', false);
                    });
                break;

            case 'none':
                $query->whereDoesntHave('subscriptions');
                break;
        }
    }

    protected function applySorting(Builder $query, string $sortBy, string $sortDirection): void
    {
        $query->orderBy($sortBy, $sortDirection);

        if ($sortBy !== 'id') {
            $query->orderByDesc('id');
        }
    }

    protected function buildSummary(Carbon $today, string $period = 'all_time', ?string $from = null, ?string $to = null): array
    {
        $todayString = $today->toDateString();
        $activeSchools = School::where('is_active', true)->count();

        return [
            'total_schools' => School::count(),
            'active_schools' => $activeSchools,
            'total_active_schools' => $activeSchools,
            'inactive_schools' => School::where('is_active', false)->count(),
            'total_students' => Student::count(),
            'active_students' => Student::where('is_active', true)->count(),
            'total_teachers' => Teacher::count(),
            'active_teachers' => Teacher::where('is_active', true)->count(),
            'schools_with_active_subscriptions' => School::whereHas('subscriptions', function (Builder $query) use ($todayString) {
                $this->applyCurrentSubscriptionScope($query, $todayString);
            })->count(),
            'financial' => $this->buildFinancialSummary($period, $from, $to),
        ];
    }

    protected function buildFinancialSummary(string $period = 'all_time', ?string $from = null, ?string $to = null): array
    {
        $now = Carbon::now();

        // Base queries
        $paymentsQuery = Payment::where('status', 'completed');
        $expensesQuery = Expense::query();

        $label = 'All Time';

        if ($period === 'today') {
            $paymentsQuery->whereDate('paid_at', $now->toDateString());
            $expensesQuery->whereDate('spent_at', $now->toDateString());
            $label = 'Today (' . $now->format('M d, Y') . ')';
        } elseif ($period === 'this_month') {
            $paymentsQuery->whereMonth('paid_at', $now->month)->whereYear('paid_at', $now->year);
            $expensesQuery->whereMonth('spent_at', $now->month)->whereYear('spent_at', $now->year);
            $label = 'This Month (' . $now->format('F Y') . ')';
        } elseif ($period === 'this_year') {
            $paymentsQuery->whereYear('paid_at', $now->year);
            $expensesQuery->whereYear('spent_at', $now->year);
            $label = 'This Year (' . $now->year . ')';
        } elseif ($period === 'last_30_days') {
            $paymentsQuery->where('paid_at', '>=', $now->copy()->subDays(30));
            $expensesQuery->where('spent_at', '>=', $now->copy()->subDays(30)->toDateString());
            $label = 'Last 30 Days';
        } elseif ($from || $to) {
            if ($from && $to) {
                $paymentsQuery->whereBetween('paid_at', [$from . ' 00:00:00', $to . ' 23:59:59']);
                $expensesQuery->whereBetween('spent_at', [$from, $to]);
                $label = Carbon::parse($from)->format('M d, Y') . ' – ' . Carbon::parse($to)->format('M d, Y');
            } elseif ($from) {
                $paymentsQuery->where('paid_at', '>=', $from . ' 00:00:00');
                $expensesQuery->where('spent_at', '>=', $from);
                $label = 'From ' . Carbon::parse($from)->format('M d, Y');
            } elseif ($to) {
                $paymentsQuery->where('paid_at', '<=', $to . ' 23:59:59');
                $expensesQuery->where('spent_at', '<=', $to);
                $label = 'Up to ' . Carbon::parse($to)->format('M d, Y');
            }
        }

        // 1. Total Revenue: Sum of completed payments (exclude failed, pending, refunded)
        $totalRevenue = (float) $paymentsQuery->sum('amount');

        // 2. Total Expenses: Sum of recorded expenses in backend
        $totalExpenses = (float) $expensesQuery->sum('amount');

        // 3. Net Profit: Total Revenue - Total Expenses
        $netProfit = round($totalRevenue - $totalExpenses, 2);

        // Precalculated Comparison Breakdowns
        $allTimeRevenue = (float) Payment::where('status', 'completed')->sum('amount');
        $allTimeExpenses = (float) Expense::sum('amount');
        $allTimeProfit = round($allTimeRevenue - $allTimeExpenses, 2);

        $monthRevenue = (float) Payment::where('status', 'completed')
            ->whereMonth('paid_at', $now->month)
            ->whereYear('paid_at', $now->year)
            ->sum('amount');
        $monthExpenses = (float) Expense::whereMonth('spent_at', $now->month)
            ->whereYear('spent_at', $now->year)
            ->sum('amount');
        $monthProfit = round($monthRevenue - $monthExpenses, 2);

        $yearRevenue = (float) Payment::where('status', 'completed')
            ->whereYear('paid_at', $now->year)
            ->sum('amount');
        $yearExpenses = (float) Expense::whereYear('spent_at', $now->year)
            ->sum('amount');
        $yearProfit = round($yearRevenue - $yearExpenses, 2);

        return [
            'period'         => $period,
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
    }

    protected function buildTopSchools()
    {
        return School::query()
            ->select(['id', 'name', 'school_key', 'admin_email', 'is_active'])
            ->withCount(['students', 'teachers'])
            ->orderByDesc('students_count')
            ->orderBy('name')
            ->limit(5)
            ->get()
            ->map(function (School $school) {
                return [
                    'id' => $school->id,
                    'name' => $school->name,
                    'school_key' => $school->school_key,
                    'admin_email' => $school->admin_email,
                    'is_active' => (bool) $school->is_active,
                    'students_count' => (int) $school->students_count,
                    'teachers_count' => (int) $school->teachers_count,
                ];
            })
            ->values();
    }

    protected function transformSchoolListItem(School $school, Carbon $today): array
    {
        $latestSubscription = $school->subscriptions->first();
        $currentSubscription = $school->subscriptions->first(
            fn(Subscription $subscription) => $this->isCurrentSubscription($subscription, $today)
        );
        $displaySubscription = $currentSubscription ?? $latestSubscription;

        return [
            'id' => $school->id,
            'name' => $school->name,
            'slug' => $school->slug,
            'school_key' => $school->school_key,
            'admin_email' => $school->admin_email,
            'admin' => [
                'name' => $school->admin?->name,
                'email' => $school->admin?->email ?? $school->admin_email,
            ],
            'status' => $school->is_active ? 'active' : 'inactive',
            'is_active' => (bool) $school->is_active,
            'students_count' => (int) $school->students_count,
            'active_students_count' => (int) $school->active_students_count,
            'inactive_students_count' => max((int) $school->students_count - (int) $school->active_students_count, 0),
            'teachers_count' => (int) $school->teachers_count,
            'active_teachers_count' => (int) $school->active_teachers_count,
            'inactive_teachers_count' => max((int) $school->teachers_count - (int) $school->active_teachers_count, 0),
            'subscription_status' => $this->resolveSchoolSubscriptionStatus($latestSubscription, $currentSubscription, $today),
            'subscription_plan' => $displaySubscription?->plan,
            'subscription_start_date' => $this->serializeDate($displaySubscription?->start_date),
            'subscription_end_date' => $this->serializeDate($displaySubscription?->end_date),
            'has_active_subscription' => $currentSubscription !== null,
            'created_at' => $school->created_at?->toISOString(),
            'updated_at' => $school->updated_at?->toISOString(),
        ];
    }

    protected function transformSchoolDetail(School $school, Carbon $today): array
    {
        $latestSubscription = $school->subscriptions->first();
        $currentSubscription = $school->subscriptions->first(
            fn(Subscription $subscription) => $this->isCurrentSubscription($subscription, $today)
        );

        return [
            'id' => $school->id,
            'name' => $school->name,
            'slug' => $school->slug,
            'school_key' => $school->school_key,
            'admin_email' => $school->admin_email,
            'admin' => [
                'name' => $school->admin?->name,
                'email' => $school->admin?->email ?? $school->admin_email,
            ],
            'status' => $school->is_active ? 'active' : 'inactive',
            'is_active' => (bool) $school->is_active,
            'students' => [
                'total' => (int) $school->students_count,
                'active' => (int) $school->active_students_count,
                'inactive' => max((int) $school->students_count - (int) $school->active_students_count, 0),
                'male' => (int) $school->male_students_count,
                'female' => (int) $school->female_students_count,
            ],
            'teachers' => [
                'total' => (int) $school->teachers_count,
                'active' => (int) $school->active_teachers_count,
                'inactive' => max((int) $school->teachers_count - (int) $school->active_teachers_count, 0),
            ],
            'users_count' => (int) $school->users_count,
            'branches_count' => (int) $school->branches_count,
            'subscriptions_count' => (int) $school->subscriptions_count,
            'subscription_status' => $this->resolveSchoolSubscriptionStatus($latestSubscription, $currentSubscription, $today),
            'current_subscription' => $this->serializeSubscription($currentSubscription, $today),
            'latest_subscription' => $this->serializeSubscription($latestSubscription, $today),
            'subscription_history' => $school->subscriptions
                ->map(fn(Subscription $subscription) => $this->serializeSubscription($subscription, $today))
                ->values(),
            'created_at' => $school->created_at?->toISOString(),
            'updated_at' => $school->updated_at?->toISOString(),
        ];
    }

    protected function applyCurrentSubscriptionScope(Builder $query, string $todayString): void
    {
        $query
            ->where('active', true)
            ->whereDate('start_date', '<=', $todayString)
            ->whereDate('end_date', '>=', $todayString);
    }

    protected function isCurrentSubscription(Subscription $subscription, Carbon $today): bool
    {
        if (!$subscription->active || !$subscription->start_date || !$subscription->end_date) {
            return false;
        }

        return $subscription->start_date->lte($today) && $subscription->end_date->gte($today);
    }

    protected function resolveSchoolSubscriptionStatus(?Subscription $latestSubscription, ?Subscription $currentSubscription, Carbon $today): string
    {
        if ($currentSubscription) {
            return 'active';
        }

        if (!$latestSubscription) {
            return 'none';
        }

        return $this->resolveSubscriptionStatus($latestSubscription, $today);
    }

    protected function resolveSubscriptionStatus(Subscription $subscription, Carbon $today): string
    {
        if (!$subscription->active) {
            return 'inactive';
        }

        if ($subscription->start_date && $subscription->start_date->gt($today)) {
            return 'scheduled';
        }

        if ($subscription->end_date && $subscription->end_date->lt($today)) {
            return 'expired';
        }

        return 'active';
    }

    protected function serializeSubscription(?Subscription $subscription, Carbon $today): ?array
    {
        if (!$subscription) {
            return null;
        }

        return [
            'id' => $subscription->id,
            'plan' => $subscription->plan,
            'amount' => $subscription->amount !== null ? (float) $subscription->amount : null,
            'active' => (bool) $subscription->active,
            'status' => $this->resolveSubscriptionStatus($subscription, $today),
            'start_date' => $this->serializeDate($subscription->start_date),
            'end_date' => $this->serializeDate($subscription->end_date),
            'created_at' => $subscription->created_at?->toISOString(),
            'updated_at' => $subscription->updated_at?->toISOString(),
        ];
    }

    protected function serializeDate($date): ?string
    {
        if (!$date) {
            return null;
        }

        return $date instanceof Carbon ? $date->toDateString() : Carbon::parse($date)->toDateString();
    }
}
