<?php

namespace App\Http\Controllers\Admin\V01;

use App\Models\Expense;
use App\Services\AuditService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class ExpenseController extends Controller
{
    /**
     * Display a listing of recorded expenses.
     */
    public function index(Request $request): JsonResponse
    {
        $filters = $request->validate([
            'search'         => 'nullable|string|max:255',
            'category'       => 'nullable|string|max:50',
            'period'         => 'nullable|in:all_time,this_month,this_year,last_30_days,today',
            'from_date'      => 'nullable|date',
            'to_date'        => 'nullable|date',
            'per_page'       => 'nullable|integer|min:1|max:1000',
            'sort_by'        => 'nullable|in:spent_at,amount,created_at,title',
            'sort_direction' => 'nullable|in:asc,desc',
        ]);

        $query = Expense::query()->with('recorder:id,name,email');

        if (!empty($filters['search'])) {
            $search = trim($filters['search']);
            $query->where(function ($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                  ->orWhere('notes', 'like', "%{$search}%");
            });
        }

        if (!empty($filters['category'])) {
            $query->where('category', $filters['category']);
        }

        // Apply specific date filters if provided
        if (!empty($filters['from_date'])) {
            $query->whereDate('spent_at', '>=', $filters['from_date']);
        }
        if (!empty($filters['to_date'])) {
            $query->whereDate('spent_at', '<=', $filters['to_date']);
        }

        // If no explicit from_date/to_date but a period is specified
        if (empty($filters['from_date']) && empty($filters['to_date']) && !empty($filters['period'])) {
            $today = Carbon::today();
            switch ($filters['period']) {
                case 'today':
                    $query->where(function ($q) use ($today) {
                        $q->whereDate('spent_at', $today->toDateString())
                          ->orWhere(fn($sq) => $sq->whereNull('spent_at')->whereDate('created_at', $today));
                    });
                    break;
                case 'this_month':
                    $start = $today->copy()->startOfMonth()->toDateString();
                    $end = $today->copy()->endOfMonth()->toDateString();
                    $query->where(function ($q) use ($start, $end) {
                        $q->whereBetween('spent_at', [$start, $end])
                          ->orWhere(fn($sq) => $sq->whereNull('spent_at')->whereBetween('created_at', [$start, $end]));
                    });
                    break;
                case 'this_year':
                    $start = $today->copy()->startOfYear()->toDateString();
                    $end = $today->copy()->endOfYear()->toDateString();
                    $query->where(function ($q) use ($start, $end) {
                        $q->whereBetween('spent_at', [$start, $end])
                          ->orWhere(fn($sq) => $sq->whereNull('spent_at')->whereBetween('created_at', [$start, $end]));
                    });
                    break;
                case 'last_30_days':
                    $start = $today->copy()->subDays(30)->toDateString();
                    $end = $today->copy()->toDateString();
                    $query->where(function ($q) use ($start, $end) {
                        $q->whereBetween('spent_at', [$start, $end])
                          ->orWhere(fn($sq) => $sq->whereNull('spent_at')->whereBetween('created_at', [$start, $end]));
                    });
                    break;
                case 'all_time':
                default:
                    // No date restriction
                    break;
            }
        }

        $sortBy = $filters['sort_by'] ?? 'spent_at';
        $sortDir = $filters['sort_direction'] ?? 'desc';
        $query->orderBy($sortBy, $sortDir)->orderByDesc('id');

        $perPage = (int) ($filters['per_page'] ?? 15);
        $paginator = $query->paginate($perPage);

        $filteredExpensesSum = (float) (clone $query)->sum('amount');
        $allTimeExpensesSum = (float) Expense::sum('amount');

        return $this->returnSuccess('Expenses retrieved successfully', [
            'expenses'          => $paginator->items(),
            'period_expenses'   => round($filteredExpensesSum, 2),
            'total_expenses'    => round($allTimeExpensesSum, 2),
            'active_period'     => $filters['period'] ?? 'all_time',
            'pagination'        => [
                'current_page' => $paginator->currentPage(),
                'last_page'    => $paginator->lastPage(),
                'per_page'     => $paginator->perPage(),
                'total'        => $paginator->total(),
            ],
        ]);
    }

    /**
     * Store a newly created expense.
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'title'    => 'required|string|max:255',
            'amount'   => 'required|numeric|min:0.01',
            'currency' => 'nullable|string|max:3',
            'category' => 'nullable|string|max:50',
            'spent_at' => 'nullable|date',
            'notes'    => 'nullable|string|max:1000',
        ]);

        $actorId = Auth::guard('api')->id();

        $expense = Expense::create([
            'title'       => $validated['title'],
            'amount'      => round((float) $validated['amount'], 2),
            'currency'    => strtoupper($validated['currency'] ?? 'USD'),
            'category'    => strtolower($validated['category'] ?? 'other'),
            'spent_at'    => $validated['spent_at'] ?? Carbon::today()->toDateString(),
            'recorded_by' => $actorId,
            'notes'       => $validated['notes'] ?? null,
        ]);

        if (class_exists(AuditService::class)) {
            AuditService::record(
                action:      'expense.created',
                target:      $expense,
                new:         $expense->toArray(),
                description: "Expense recorded: {$expense->title} (\${$expense->amount})",
                severity:    'info',
            );
        }

        return $this->returnSuccess('Expense recorded successfully', [
            'expense' => $expense->load('recorder:id,name,email'),
        ], 201);
    }

    /**
     * Display the specified expense.
     */
    public function show(Expense $expense): JsonResponse
    {
        return $this->returnSuccess('Expense details fetched successfully', [
            'expense' => $expense->load('recorder:id,name,email'),
        ]);
    }

    /**
     * Update the specified expense.
     */
    public function update(Request $request, Expense $expense): JsonResponse
    {
        $validated = $request->validate([
            'title'    => 'sometimes|required|string|max:255',
            'amount'   => 'sometimes|required|numeric|min:0.01',
            'currency' => 'nullable|string|max:3',
            'category' => 'nullable|string|max:50',
            'spent_at' => 'nullable|date',
            'notes'    => 'nullable|string|max:1000',
        ]);

        $old = $expense->toArray();

        $expense->fill($validated);
        if (isset($validated['currency'])) {
            $expense->currency = strtoupper($validated['currency']);
        }
        if (isset($validated['category'])) {
            $expense->category = strtolower($validated['category']);
        }
        $expense->save();

        if (class_exists(AuditService::class)) {
            AuditService::record(
                action:      'expense.updated',
                target:      $expense,
                old:         $old,
                new:         $expense->toArray(),
                description: "Expense updated: {$expense->title} (\${$expense->amount})",
                severity:    'info',
            );
        }

        return $this->returnSuccess('Expense updated successfully', [
            'expense' => $expense->load('recorder:id,name,email'),
        ]);
    }

    /**
     * Remove the specified expense.
     */
    public function destroy(Expense $expense): JsonResponse
    {
        $old = $expense->toArray();
        $expense->delete();

        if (class_exists(AuditService::class)) {
            AuditService::record(
                action:      'expense.deleted',
                target:      $expense,
                old:         $old,
                description: "Expense deleted: {$expense->title}",
                severity:    'warning',
            );
        }

        return $this->returnSuccess('Expense deleted successfully');
    }
}
