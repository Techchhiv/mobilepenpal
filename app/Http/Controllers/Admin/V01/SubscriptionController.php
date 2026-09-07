<?php

namespace App\Http\Controllers\Admin\V01;

use App\Http\Requests\Admin\Subscription\ActivateSubscriptionRequest;
use App\Http\Requests\Admin\Subscription\DeactivateSubscriptionRequest;
use App\Http\Resources\Admin\V01\Subscription\InvoiceResource;
use App\Models\School;
use App\Models\Student;
use App\Models\Subscription;
use App\Services\SubscriptionBillingService;
use Illuminate\Http\Request;

class SubscriptionController extends Controller
{
    public function __construct(protected SubscriptionBillingService $billing) {}

    // ── Activate ─────────────────────────────────────────────────────────────

    public function activateSchool(ActivateSubscriptionRequest $request, $schoolId)
    {
        $school = School::find($schoolId);
        if (! $school) {
            return $this->returnError('School not found', 404);
        }

        try {
            $result = $this->billing->activateSchool($school, $request->billingData());
        } catch (\RuntimeException $e) {
            return $this->returnError($e->getMessage(), 400);
        }

        $this->setCode(201);
        $this->setMessage('School subscription activated successfully.');
        $this->setResult('subscription', $result['subscription']);
        $this->setResult('invoice', new InvoiceResource($result['invoice']));
        return $this->returnResponse(201);
    }

    public function activateStudent(ActivateSubscriptionRequest $request, $studentId)
    {
        $student = Student::find($studentId);
        if (! $student) {
            return $this->returnError('Student not found', 404);
        }

        try {
            $result = $this->billing->activateStudent($student, $request->billingData());
        } catch (\RuntimeException $e) {
            return $this->returnError($e->getMessage(), 400);
        }

        $this->setCode(201);
        $this->setMessage('Student subscription activated successfully.');
        $this->setResult('subscription', $result['subscription']);
        $this->setResult('invoice', new InvoiceResource($result['invoice']));
        return $this->returnResponse(201);
    }

    // ── Renew ─────────────────────────────────────────────────────────────────

    public function renewSchool(ActivateSubscriptionRequest $request, $schoolId)
    {
        $school = School::find($schoolId);
        if (! $school) {
            return $this->returnError('School not found', 404);
        }

        try {
            $result = $this->billing->renewSchool($school, $request->billingData());
        } catch (\RuntimeException $e) {
            return $this->returnError($e->getMessage(), 400);
        }

        $this->setCode(201);
        $this->setMessage('School subscription renewed successfully.');
        $this->setResult('subscription', $result['subscription']);
        $this->setResult('invoice', new InvoiceResource($result['invoice']));
        return $this->returnResponse(201);
    }

    public function renewStudent(ActivateSubscriptionRequest $request, $studentId)
    {
        $student = Student::find($studentId);
        if (! $student) {
            return $this->returnError('Student not found', 404);
        }

        try {
            $result = $this->billing->renewStudent($student, $request->billingData());
        } catch (\RuntimeException $e) {
            return $this->returnError($e->getMessage(), 400);
        }

        $this->setCode(201);
        $this->setMessage('Student subscription renewed successfully.');
        $this->setResult('subscription', $result['subscription']);
        $this->setResult('invoice', new InvoiceResource($result['invoice']));
        return $this->returnResponse(201);
    }

    // ── Deactivate ───────────────────────────────────────────────────────────

    public function deactivateSchool(DeactivateSubscriptionRequest $request, $schoolId)
    {
        $school = School::find($schoolId);
        if (! $school) {
            return $this->returnError('School not found', 404);
        }

        try {
            $result = $this->billing->deactivateSchool(
                $school,
                $request->reason,
                (bool) $request->boolean('void_invoice')
            );
        } catch (\RuntimeException $e) {
            return $this->returnError($e->getMessage(), 400);
        }

        $this->setMessage('School subscription deactivated successfully.');
        $this->setResult('subscription', $result['subscription']);
        if ($result['invoice']) {
            $this->setResult('invoice', new InvoiceResource($result['invoice']));
        }
        return $this->returnResponse();
    }

    public function deactivateStudent(DeactivateSubscriptionRequest $request, $studentId)
    {
        $student = Student::find($studentId);
        if (! $student) {
            return $this->returnError('Student not found', 404);
        }

        try {
            $result = $this->billing->deactivateStudent(
                $student,
                $request->reason,
                (bool) $request->boolean('void_invoice')
            );
        } catch (\RuntimeException $e) {
            return $this->returnError($e->getMessage(), 400);
        }

        $this->setMessage('Student subscription deactivated successfully.');
        $this->setResult('subscription', $result['subscription']);
        if ($result['invoice']) {
            $this->setResult('invoice', new InvoiceResource($result['invoice']));
        }
        return $this->returnResponse();
    }

    // ── List Endpoints ────────────────────────────────────────────────────────

    public function schools(Request $request)
    {
        $today = now()->toDateString();
        $schools = School::with([
            'subscriptions' => function ($query) {
                $query->orderBy('end_date', 'desc');
            }
        ])->get();

        $schoolsData = $schools->map(function ($school) use ($today) {
            $latestSubscription = $school->subscriptions->first();
            $currentlyActive = $school->subscriptions
                ->where('active', true)
                ->filter(fn ($sub) => (
                    (! $sub->start_date || $sub->start_date->toDateString() <= $today) &&
                    (! $sub->end_date || $sub->end_date->toDateString() >= $today)
                ))
                ->isNotEmpty();

            return [
                'id'                      => $school->id,
                'name'                    => $school->name,
                'has_active_subscription' => $currentlyActive,
                'current_plan'            => $latestSubscription ? $latestSubscription->plan : null,
                'subscription_end_date'   => $latestSubscription ? $latestSubscription->end_date : null,
            ];
        });

        $this->setResult('schools', $schoolsData);
        return $this->returnResponse();
    }

    public function students(Request $request)
    {
        $today = now()->toDateString();
        $students = Student::whereNull('school_id')
            ->with([
                'subscriptions' => function ($query) {
                    $query->orderBy('end_date', 'desc');
                }
            ])->get();

        $studentsData = $students->map(function ($student) use ($today) {
            $latestSubscription = $student->subscriptions->first();
            $currentlyActive = $student->subscriptions
                ->where('active', true)
                ->filter(fn ($sub) => (
                    (! $sub->start_date || $sub->start_date->toDateString() <= $today) &&
                    (! $sub->end_date || $sub->end_date->toDateString() >= $today)
                ))
                ->isNotEmpty();

            return [
                'id'                      => $student->id,
                'first_name'              => $student->first_name,
                'last_name'               => $student->last_name,
                'has_active_subscription' => $currentlyActive,
                'current_plan'            => $latestSubscription ? $latestSubscription->plan : null,
                'subscription_end_date'   => $latestSubscription ? $latestSubscription->end_date : null,
            ];
        });

        $this->setResult('students', $studentsData);
        return $this->returnResponse();
    }

    public function active()
    {
        $today = now()->toDateString();
        $subscriptions = Subscription::with(['school', 'student'])
            ->where('active', true)
            ->where('start_date', '<=', $today)
            ->where('end_date', '>=', $today)
            ->orderBy('end_date', 'desc')
            ->get();

        $this->setResult('subscriptions', $subscriptions);
        return $this->returnResponse();
    }
}
