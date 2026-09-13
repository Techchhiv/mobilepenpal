<?php

namespace App\Http\Controllers;

use App\Models\School;
use App\Models\Subscription;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use App\Services\AuditService;

class SchoolController extends Controller
{
  public function __construct()
{
    $this->middleware('auth:api')->except(['publicList']);
   
}

    public function index(Request $request)
    {
        $today = Carbon::today();
        $todayString = $today->toDateString();
        $in30DaysString = $today->copy()->addDays(30)->toDateString();

        $query = School::with([
            'admin:id,school_id,name,email',
            'subscriptions' => function ($q) {
                $q->orderByDesc('end_date')->orderByDesc('id');
            },
        ])
        ->withCount(['students', 'teachers']);

        // 1. Search (name, school_key, admin_email)
        if ($request->filled('search')) {
            $search = trim($request->input('search'));
            $query->where(function (Builder $q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('school_key', 'like', "%{$search}%")
                  ->orWhere('admin_email', 'like', "%{$search}%");
            });
        }

        // 2. School Status (active / inactive)
        if ($request->filled('school_status')) {
            $schoolStatus = $request->input('school_status');
            if ($schoolStatus === 'active') {
                $query->where('is_active', true);
            } elseif ($schoolStatus === 'inactive') {
                $query->where('is_active', false);
            }
        }

        // 3. Plan (monthly / yearly)
        if ($request->filled('plan')) {
            $plan = $request->input('plan');
            $query->whereHas('subscriptions', function (Builder $q) use ($plan) {
                $q->where('plan', $plan);
            });
        }

        // 4. Subscription Status (active, expiring_soon, expired, none)
        if ($request->filled('subscription_status')) {
            $subStatus = $request->input('subscription_status');
            switch ($subStatus) {
                case 'active':
                    $query->whereHas('subscriptions', function (Builder $q) use ($todayString) {
                        $q->where('active', true)
                          ->whereDate('start_date', '<=', $todayString)
                          ->whereDate('end_date', '>=', $todayString);
                    });
                    break;
                case 'expiring_soon':
                case 'expiring':
                    $query->whereHas('subscriptions', function (Builder $q) use ($todayString, $in30DaysString) {
                        $q->where('active', true)
                          ->whereDate('start_date', '<=', $todayString)
                          ->whereDate('end_date', '>=', $todayString)
                          ->whereDate('end_date', '<=', $in30DaysString);
                    });
                    break;
                case 'expired':
                    $query->whereDoesntHave('subscriptions', function (Builder $q) use ($todayString) {
                        $q->where('active', true)
                          ->whereDate('start_date', '<=', $todayString)
                          ->whereDate('end_date', '>=', $todayString);
                    })->whereHas('subscriptions', function (Builder $q) use ($todayString) {
                        $q->whereDate('end_date', '<', $todayString);
                    });
                    break;
                case 'none':
                case 'no_subscription':
                    $query->whereDoesntHave('subscriptions');
                    break;
            }
        }

        $perPage = (int) $request->input('per_page', 10);
        if ($perPage < 1) $perPage = 10;
        if ($perPage > 100) $perPage = 100;

        $paginator = $query->orderByDesc('id')->paginate($perPage);

        $paginator->getCollection()->transform(function (School $school) use ($today) {
            return $this->transformSchoolItem($school, $today);
        });

        $summary = [
            'total'    => School::count(),
            'active'   => School::where('is_active', true)->count(),
            'inactive' => School::where('is_active', false)->count(),
        ];

        $payload = $paginator->toArray();
        $payload['summary'] = $summary;

        return response()->json($payload);
    }

    protected function transformSchoolItem(School $school, Carbon $today): array
    {
        $latestSubscription = $school->subscriptions->first();
        $currentSubscription = $school->subscriptions->first(function (Subscription $sub) use ($today) {
            return $sub->active && $sub->start_date && $sub->end_date &&
                $sub->start_date->lte($today) && $sub->end_date->gte($today);
        });
        $displaySubscription = $currentSubscription ?? $latestSubscription;

        $subStatus = 'none';
        if ($currentSubscription) {
            if ($currentSubscription->end_date && $today->lte($currentSubscription->end_date) && $today->diffInDays($currentSubscription->end_date, false) <= 30) {
                $subStatus = 'expiring_soon';
            } else {
                $subStatus = 'active';
            }
        } elseif ($latestSubscription) {
            if (!$latestSubscription->active) {
                $subStatus = 'inactive';
            } elseif ($latestSubscription->start_date && $latestSubscription->start_date->gt($today)) {
                $subStatus = 'scheduled';
            } elseif ($latestSubscription->end_date && $latestSubscription->end_date->lt($today)) {
                $subStatus = 'expired';
            } else {
                $subStatus = 'active';
            }
        }

        return [
            'id'                      => $school->id,
            'name'                    => $school->name,
            'slug'                    => $school->slug,
            'school_key'              => $school->school_key,
            'admin_email'             => $school->admin_email,
            'admin'                   => [
                'name'  => $school->admin?->name,
                'email' => $school->admin?->email ?? $school->admin_email,
            ],
            'status'                  => $school->is_active ? 'active' : 'inactive',
            'is_active'               => (bool) $school->is_active,
            'students_count'          => (int) ($school->students_count ?? 0),
            'teachers_count'          => (int) ($school->teachers_count ?? 0),
            'subscription_plan'       => $displaySubscription?->plan,
            'subscription_status'     => $subStatus,
            'subscription_start_date' => $displaySubscription?->start_date ? Carbon::parse($displaySubscription->start_date)->toDateString() : null,
            'subscription_end_date'   => $displaySubscription?->end_date ? Carbon::parse($displaySubscription->end_date)->toDateString() : null,
            'has_active_subscription' => $currentSubscription !== null,
            'created_at'              => $school->created_at?->toISOString(),
            'updated_at'              => $school->updated_at?->toISOString(),
        ];
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255|unique:schools,name',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|string|min:8',
            'school_key' => 'required|string|unique:schools,school_key',
        ]);

        $school = School::create([
            'name'       => $request->name,
            'slug'       => Str::slug($request->name),
            'school_key' => $request->school_key,
            'admin_email'=> $request->email,
        ]);

        $user = User::create([
            'name'      => $request->name . ' Admin',
            'email'     => $request->email,
            'password'  => Hash::make($request->password),
            'school_id' => $school->id,
        ]);

        $user->assignRole('school-admin');

        AuditService::record(
            action: 'school.created',
            target: $school,
            new: ['name' => $school->name, 'school_key' => '[REDACTED]', 'admin_email' => $school->admin_email],
            description: "School created: {$school->name}",
            severity: 'info'
        );

        return response()->json([
            'message' => 'School created successfully',
            'school'  => $school,
            'admin'   => $user,
        ], 201);
    }

    public function show(School $school)
    {
        return response()->json($school->load('admin'));
    }

    public function update(Request $request, School $school)
    {
        $request->validate([
            'name' => 'sometimes|required|string|max:255|unique:schools,name,' . $school->id,
            'is_active' => 'boolean',
            'school_key' => 'sometimes|required|string|unique:schools,school_key,' . $school->id,
            'admin_email' => 'sometimes|required|email',
        ]);

        // Track what changed
        $oldValues = [
            'name' => $school->getOriginal('name'),
            'is_active' => $school->getOriginal('is_active'),
            'school_key' => $school->getOriginal('school_key'),
            'admin_email' => $school->getOriginal('admin_email'),
        ];

        if ($request->has('name')) {
            $school->name = $request->name;
            $school->slug = Str::slug($request->name);
        }

        if ($request->has('is_active')) {
            $school->is_active = $request->boolean('is_active');
        }

        if ($request->has('school_key')) {
            $school->school_key = $request->school_key;
        }

        if ($request->has('admin_email')) {
            $school->admin_email = $request->admin_email;
        }

        $school->save();
        $newValues = [
            'name' => $school->name,
            'is_active' => $school->is_active,
            'school_key' => $school->school_key,
            'admin_email' => $school->admin_email,
        ];

        $action   = ($oldValues['is_active'] !== $newValues['is_active']) ? 'school.status.changed' : 'school.updated';
        $severity = ($action === 'school.status.changed') ? 'warning' : 'info';

        AuditService::record(
            action: $action,
            target: $school,
            old: $oldValues,
            new: $newValues,
            description: "School updated: {$school->name}",
            severity: $severity
        );

        return response()->json([
            'message' => 'School updated',
            'school'  => $school,
        ]);
    }

    public function destroy(School $school)
    {
        $snapshot = ['name' => $school->name, 'admin_email' => $school->admin_email, 'is_active' => $school->is_active];

        AuditService::record(
            action: 'school.deleted',
            target: $school,
            old: $snapshot,
            description: "School deleted: {$school->name}",
            severity: 'warning',
            metadata: $snapshot
        );

        $school->delete();

        return response()->json([
            'message' => 'School deleted'
        ], 200);
    }

    public function generateKey()
    {
        do {
            $key = 'SCH-' . strtoupper(Str::random(6));
        } while (School::where('school_key', $key)->exists());

        return response()->json(['key' => $key]);
    }

    // Public endpoint for student registration
    public function publicList()
    {
        $schools = School::where('is_active', true)
            ->select(['id', 'name', 'school_key'])
            ->orderBy('name')
            ->get();

        return response()->json([
            'data' => $schools
        ]);
    }
}
