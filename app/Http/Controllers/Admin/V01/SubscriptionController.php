<?php

namespace App\Http\Controllers\Admin\V01;

use App\Models\School;
use App\Models\Student;
use App\Models\Subscription;
use Carbon\Carbon;
use Illuminate\Http\Request;
use App\Services\AuditService;

class SubscriptionController extends Controller
{
    public function activateSchool(Request $request, $schoolId)
    {
        $validated = $request->validate([
            'plan' => 'required|in:monthly,yearly',
            'amount' => 'required|numeric|min:0',
        ]);

        $school = School::find($schoolId);
        if (!$school)
            return $this->returnError('School not found', 404);

        if (Subscription::where('school_id', $school->id)->where('active', true)->where('end_date', '>=', now())->exists()) {
            return $this->returnError('School already has an active subscription. Please renew instead.', 400);
        }

        $start = now();
        $end = $validated['plan'] === 'monthly'
            ? $start->copy()->addMonth()
            : $start->copy()->addYear();

        $subscription = Subscription::create([
            'school_id'  => $school->id,
            'plan'       => $validated['plan'],
            'amount'     => $validated['amount'],
            'start_date' => $start,
            'end_date'   => $end,
            'active'     => true,
        ]);

        AuditService::record(
            action: 'subscription.activated',
            target: $school,
            new: [
                'plan'       => $validated['plan'],
                'amount'     => $validated['amount'],
                'start_date' => $start->toDateString(),
                'end_date'   => $end->toDateString(),
                'active'     => true,
            ],
            description: "School subscription activated for: {$school->name} (Plan: {$validated['plan']})",
            severity: 'info',
            metadata: ['school_name' => $school->name, 'subscription_id' => $subscription->id]
        );

        $this->setCode(201);
        $this->setMessage('School subscription activated successfully');
        $this->setResult('subscription', $subscription);
        return $this->returnResponse(201);
    }

    public function activateStudent(Request $request, $studentId)
    {
        $validated = $request->validate([
            'plan' => 'required|in:monthly,yearly',
            'amount' => 'required|numeric|min:0',
        ]);

        $student = Student::find($studentId);
        if (!$student)
            return $this->returnError('Student not found', 404);

        if (Subscription::where('student_id', $student->id)->where('active', true)->where('end_date', '>=', now())->exists()) {
            return $this->returnError('Student already has an active subscription. Please renew instead.', 400);
        }

        $start = now();
        $end = $validated['plan'] === 'monthly'
            ? $start->copy()->addMonth()
            : $start->copy()->addYear();

        $subscription = Subscription::create([
            'student_id' => $student->id,
            'plan'       => $validated['plan'],
            'amount'     => $validated['amount'],
            'start_date' => $start,
            'end_date'   => $end,
            'active'     => true,
        ]);

        AuditService::record(
            action: 'subscription.activated',
            target: $student,
            new: [
                'plan'       => $validated['plan'],
                'amount'     => $validated['amount'],
                'start_date' => $start->toDateString(),
                'end_date'   => $end->toDateString(),
                'active'     => true,
            ],
            description: "Student subscription activated for: {$student->first_name} {$student->last_name} (Plan: {$validated['plan']})",
            severity: 'info',
            metadata: ['student_name' => "{$student->first_name} {$student->last_name}", 'subscription_id' => $subscription->id]
        );

        $this->setCode(201);
        $this->setMessage('Student subscription activated successfully');
        $this->setResult('subscription', $subscription);
        return $this->returnResponse(201);
    }

    public function renewSchool(Request $request, $schoolId)
    {
        $validated = $request->validate([
            'plan' => 'required|in:monthly,yearly',
            'amount' => 'required|numeric|min:0',
        ]);

        $school = School::find($schoolId);
        if (!$school)
            return $this->returnError('School not found', 404);

        $latestSubscription = Subscription::where('school_id', $schoolId)
            ->where('active', true)
            ->orderBy('end_date', 'desc')
            ->first();

        $start = now();
        if ($latestSubscription && $latestSubscription->end_date > now()) {
            $start = Carbon::parse($latestSubscription->end_date);
        }

        $end = $validated['plan'] === 'monthly'
            ? $start->copy()->addMonth()
            : $start->copy()->addYear();

        $subscription = Subscription::create([
            'school_id'  => $school->id,
            'plan'       => $validated['plan'],
            'amount'     => $validated['amount'],
            'start_date' => $start,
            'end_date'   => $end,
            'active'     => true,
        ]);

        AuditService::record(
            action: 'subscription.renewed',
            target: $school,
            old: $latestSubscription ? [
                'plan'     => $latestSubscription->plan,
                'end_date' => $latestSubscription->end_date?->toDateString(),
            ] : null,
            new: [
                'plan'       => $validated['plan'],
                'amount'     => $validated['amount'],
                'start_date' => $start->toDateString(),
                'end_date'   => $end->toDateString(),
            ],
            description: "School subscription renewed for: {$school->name} (New Plan: {$validated['plan']})",
            severity: 'info',
            metadata: ['school_name' => $school->name, 'subscription_id' => $subscription->id]
        );

        $this->setCode(201);
        $this->setMessage('School subscription renewed successfully');
        $this->setResult('subscription', $subscription);
        return $this->returnResponse(201);
    }

    public function renewStudent(Request $request, $studentId)
    {
        $validated = $request->validate([
            'plan' => 'required|in:monthly,yearly',
            'amount' => 'required|numeric|min:0',
        ]);

        $student = Student::find($studentId);
        if (!$student)
            return $this->returnError('Student not found', 404);

        $latestSubscription = Subscription::where('student_id', $studentId)
            ->where('active', true)
            ->orderBy('end_date', 'desc')
            ->first();

        $start = now();
        if ($latestSubscription && $latestSubscription->end_date > now()) {
            $start = Carbon::parse($latestSubscription->end_date);
        }

        $end = $validated['plan'] === 'monthly'
            ? $start->copy()->addMonth()
            : $start->copy()->addYear();

        $subscription = Subscription::create([
            'student_id' => $student->id,
            'plan'       => $validated['plan'],
            'amount'     => $validated['amount'],
            'start_date' => $start,
            'end_date'   => $end,
            'active'     => true,
        ]);

        AuditService::record(
            action: 'subscription.renewed',
            target: $student,
            old: $latestSubscription ? [
                'plan'     => $latestSubscription->plan,
                'end_date' => $latestSubscription->end_date?->toDateString(),
            ] : null,
            new: [
                'plan'       => $validated['plan'],
                'amount'     => $validated['amount'],
                'start_date' => $start->toDateString(),
                'end_date'   => $end->toDateString(),
            ],
            description: "Student subscription renewed for: {$student->first_name} {$student->last_name} (New Plan: {$validated['plan']})",
            severity: 'info',
            metadata: ['student_name' => "{$student->first_name} {$student->last_name}", 'subscription_id' => $subscription->id]
        );

        $this->setCode(201);
        $this->setMessage('Student subscription renewed successfully');
        $this->setResult('subscription', $subscription);
        return $this->returnResponse(201);
    }

    public function schools(Request $request)
    {
        $schools = School::with([
            'subscriptions' => function ($query) {
                $query->where('active', true)
                    ->where('end_date', '>=', now())
                    ->orderBy('end_date', 'desc');
            }
        ])->get();

        $schoolsData = $schools->map(function ($school) {
            $activeSubscription = $school->subscriptions->first();
            $currentlyActive = $school->subscriptions->where('start_date', '<=', now())->where('end_date', '>=', now())->isNotEmpty();

            return [
                'id' => $school->id,
                'name' => $school->name,
                'has_active_subscription' => $currentlyActive,
                'current_plan' => $activeSubscription ? $activeSubscription->plan : null,
                'subscription_end_date' => $activeSubscription ? $activeSubscription->end_date : null,
            ];
        });

        $this->setResult('schools', $schoolsData);
        return $this->returnResponse();
    }

    public function students(Request $request)
    {
        $students = Student::whereNull('school_id')
            ->with([
                'subscriptions' => function ($query) {
                    $query->where('active', true)
                        ->where('end_date', '>=', now())
                        ->orderBy('end_date', 'desc');
                }
            ])->get();

        $studentsData = $students->map(function ($student) {
            $activeSubscription = $student->subscriptions->first();
            $currentlyActive = $student->subscriptions->where('start_date', '<=', now())->where('end_date', '>=', now())->isNotEmpty();

            return [
                'id' => $student->id,
                'first_name' => $student->first_name,
                'last_name' => $student->last_name,
                'has_active_subscription' => $currentlyActive,
                'current_plan' => $activeSubscription ? $activeSubscription->plan : null,
                'subscription_end_date' => $activeSubscription ? $activeSubscription->end_date : null,
            ];
        });

        $this->setResult('students', $studentsData);
        return $this->returnResponse();
    }

    public function active()
    {
        $subscriptions = Subscription::with(['school', 'student'])
            ->where('active', true)
            ->where('start_date', '<=', now())
            ->where('end_date', '>=', now())
            ->orderBy('end_date', 'desc')
            ->get();

        $this->setResult('subscriptions', $subscriptions);
        return $this->returnResponse();
    }
}
