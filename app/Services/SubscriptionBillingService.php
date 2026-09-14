<?php

namespace App\Services;

use App\Models\Invoice;
use App\Models\InvoiceSequence;
use App\Models\Payment;
use App\Models\School;
use App\Models\Student;
use App\Models\Subscription;
use App\Models\SystemSetting;
use Carbon\Carbon;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Throwable;

class SubscriptionBillingService
{
    // ── Pricing ────────────────────────────────────────────────────────────────

    /**
     * Get the subscription settings configured in the system.
     */
    public function getSubscriptionSettings(): array
    {
        $setting = SystemSetting::find('subscription');
        $data = $setting && is_array($setting->value) ? $setting->value : [];

        $legacyPrice = (float) ($data['monthly_price'] ?? ($data['price'] ?? 5.0));
        $legacyDiscount = (float) ($data['monthly_discount'] ?? ($data['discount'] ?? 50));

        // Fallback defaults matching SystemSettingSeeder ($5 with 50% discount = $2.50/month, $50 with 60% discount = $20.00/year, 0% tax)
        return array_merge([
            'price'            => $legacyPrice,
            'discount'         => $legacyDiscount,
            'monthly_price'    => (float) ($data['monthly_price'] ?? $legacyPrice),
            'monthly_discount' => (float) ($data['monthly_discount'] ?? $legacyDiscount),
            'yearly_price'     => (float) ($data['yearly_price'] ?? 50.0),
            'yearly_discount'  => (float) ($data['yearly_discount'] ?? 60.0),
            'tax_rate'         => 0,
            'billing_cycle'    => 'month',
            'contact_phone'    => '+855 935 248 60',
            'contact_email'    => 'info@khmerpenpal.com',
        ], $data);
    }

    /**
     * Get the detailed pricing breakdown (subtotal, discount, tax, final price) for a plan.
     */
    public function getPlanPricingDetails(string $plan): array
    {
        $settings = $this->getSubscriptionSettings();
        $taxPercent = (float) ($settings['tax_rate'] ?? 0);

        if ($plan === 'yearly') {
            $subtotal = (float) ($settings['yearly_price'] ?? 50.0);
            $discountPercent = (float) ($settings['yearly_discount'] ?? 60.0);
        } else {
            $subtotal = (float) ($settings['monthly_price'] ?? ($settings['price'] ?? 5.0));
            $discountPercent = (float) ($settings['monthly_discount'] ?? ($settings['discount'] ?? 50.0));
        }

        $discountAmount = $discountPercent > 0 ? ($subtotal * ($discountPercent / 100)) : 0.0;
        $netAmount = max(0, $subtotal - $discountAmount);
        $taxAmount = $taxPercent > 0 ? ($netAmount * ($taxPercent / 100)) : 0.0;
        $finalPrice = max(0, $netAmount + $taxAmount);

        return [
            'plan'             => $plan,
            'subtotal'         => round($subtotal, 2),
            'discount_percent' => $discountPercent,
            'discount_amount'  => round($discountAmount, 2),
            'tax_percent'      => $taxPercent,
            'tax_amount'       => round($taxAmount, 2),
            'final_price'      => round($finalPrice, 2),
            'currency'         => 'USD',
        ];
    }

    /**
     * Fetch the backend-authoritative price for a given plan.
     */
    public function getPlanPrice(string $plan): float
    {
        return $this->getPlanPricingDetails($plan)['final_price'];
    }

    /**
     * Resolve the final price: backend price unless caller explicitly provides an override_price.
     */
    public function resolvePrice(string $plan, ?float $overridePrice, bool $canOverride = true): float
    {
        if ($canOverride && $overridePrice !== null && $overridePrice >= 0) {
            return (float) $overridePrice;
        }

        return $this->getPlanPrice($plan);
    }

    // ── Invoice Number Generation ──────────────────────────────────────────────

    /**
     * Generate a unique invoice number like INV-2026-000001.
     * Uses pessimistic locking on the invoice_sequences row to prevent duplicates
     * under concurrent requests.
     *
     * MUST be called inside a DB::transaction().
     */
    public function generateInvoiceNumber(): string
    {
        $year = (int) now()->format('Y');

        $seq = DB::table('invoice_sequences')
            ->where('year', $year)
            ->lockForUpdate()
            ->first();

        if (! $seq) {
            DB::table('invoice_sequences')->insert([
                'year'          => $year,
                'last_sequence' => 0,
                'created_at'    => now(),
                'updated_at'    => now(),
            ]);
            $seq = DB::table('invoice_sequences')
                ->where('year', $year)
                ->lockForUpdate()
                ->first();
        }

        $next = $seq->last_sequence + 1;

        DB::table('invoice_sequences')
            ->where('year', $year)
            ->update(['last_sequence' => $next, 'updated_at' => now()]);

        return sprintf('INV-%d-%06d', $year, $next);
    }

    // ── Idempotency ────────────────────────────────────────────────────────────

    /**
     * Check whether an idempotency key has already been used for an invoice.
     * If so, return the existing invoice rather than creating a new one.
     */
    public function findExistingByIdempotencyKey(string $key): ?Invoice
    {
        return Invoice::where('idempotency_key', $key)
            ->with('payment')
            ->first();
    }

    // ── Activation ────────────────────────────────────────────────────────────

    /**
     * Activate a school subscription + create invoice + payment in one transaction.
     */
    public function activateSchool(School $school, array $data): array
    {
        // Idempotency check BEFORE the transaction
        if (! empty($data['idempotency_key'])) {
            $existing = $this->findExistingByIdempotencyKey($data['idempotency_key']);
            if ($existing) {
                return [
                    'subscription' => $existing->subscription,
                    'invoice'      => $existing,
                ];
            }
        }

        return DB::transaction(function () use ($school, $data) {
            $today = now()->toDateString();
            // Check for existing active subscription
            if (Subscription::where('school_id', $school->id)
                ->where('active', true)
                ->where('end_date', '>=', $today)
                ->exists()
            ) {
                throw new \RuntimeException('School already has an active subscription. Please renew instead.');
            }

            $plan  = $data['plan'];
            $price = $this->resolvePrice($plan, $data['override_price'] ?? null, $data['can_override'] ?? false);

            $start = now();
            $end   = $plan === 'monthly' ? $start->copy()->addMonth() : $start->copy()->addYear();

            // 1. Create subscription
            $subscription = Subscription::create([
                'school_id'        => $school->id,
                'plan'             => $plan,
                'amount'           => $price,
                'start_date'       => $start,
                'end_date'         => $end,
                'active'           => true,
                'idempotency_key'  => $data['idempotency_key'] ?? null,
            ]);

            // 2. Create invoice + payment
            $invoice = $this->createInvoiceAndPayment(
                subscription: $subscription,
                customerType: 'school',
                entity:       $school,
                plan:         $plan,
                price:        $price,
                start:        $start,
                end:          $end,
                data:         $data,
            );

            // 3. Audit
            AuditService::record(
                action:      'subscription.activated',
                target:      $school,
                new: [
                    'plan'           => $plan,
                    'amount'         => $price,
                    'start_date'     => $start->toDateString(),
                    'end_date'       => $end->toDateString(),
                    'invoice_number' => $invoice->invoice_number,
                ],
                description: "School subscription activated: {$school->name} (Plan: {$plan}, Invoice: {$invoice->invoice_number})",
                severity:    'info',
                metadata:    ['school_name' => $school->name, 'subscription_id' => $subscription->id, 'invoice_id' => $invoice->id],
            );

            return ['subscription' => $subscription, 'invoice' => $invoice];
        });
    }

    /**
     * Activate a student/user subscription + create invoice + payment in one transaction.
     */
    public function activateStudent(Student $student, array $data): array
    {
        if (! empty($data['idempotency_key'])) {
            $existing = $this->findExistingByIdempotencyKey($data['idempotency_key']);
            if ($existing) {
                return ['subscription' => $existing->subscription, 'invoice' => $existing];
            }
        }

        return DB::transaction(function () use ($student, $data) {
            $today = now()->toDateString();
            if (Subscription::where('student_id', $student->id)
                ->where('active', true)
                ->where('end_date', '>=', $today)
                ->exists()
            ) {
                throw new \RuntimeException('Student already has an active subscription. Please renew instead.');
            }

            $plan  = $data['plan'];
            $price = $this->resolvePrice($plan, $data['override_price'] ?? null, $data['can_override'] ?? false);

            $start = now();
            $end   = $plan === 'monthly' ? $start->copy()->addMonth() : $start->copy()->addYear();

            $subscription = Subscription::create([
                'student_id'      => $student->id,
                'plan'            => $plan,
                'amount'          => $price,
                'start_date'      => $start,
                'end_date'        => $end,
                'active'          => true,
                'idempotency_key' => $data['idempotency_key'] ?? null,
            ]);

            $invoice = $this->createInvoiceAndPayment(
                subscription: $subscription,
                customerType: 'student',
                entity:       $student,
                plan:         $plan,
                price:        $price,
                start:        $start,
                end:          $end,
                data:         $data,
            );

            AuditService::record(
                action:      'subscription.activated',
                target:      $student,
                new: [
                    'plan'           => $plan,
                    'amount'         => $price,
                    'start_date'     => $start->toDateString(),
                    'end_date'       => $end->toDateString(),
                    'invoice_number' => $invoice->invoice_number,
                ],
                description: "Student subscription activated: {$student->first_name} {$student->last_name} (Plan: {$plan}, Invoice: {$invoice->invoice_number})",
                severity:    'info',
                metadata:    ['student_id' => $student->id, 'subscription_id' => $subscription->id, 'invoice_id' => $invoice->id],
            );

            return ['subscription' => $subscription, 'invoice' => $invoice];
        });
    }

    // ── Renewal ───────────────────────────────────────────────────────────────

    /**
     * Renew a school subscription, correctly chaining the billing period.
     */
    public function renewSchool(School $school, array $data): array
    {
        if (! empty($data['idempotency_key'])) {
            $existing = $this->findExistingByIdempotencyKey($data['idempotency_key']);
            if ($existing) {
                return ['subscription' => $existing->subscription, 'invoice' => $existing];
            }
        }

        return DB::transaction(function () use ($school, $data) {
            $today = now()->toDateString();
            $latest = Subscription::where('school_id', $school->id)
                ->where('active', true)
                ->orderBy('end_date', 'desc')
                ->first();

            // Chain from existing end date if still active today or in the future
            $start = ($latest && $latest->end_date && $latest->end_date->toDateString() >= $today)
                ? Carbon::parse($latest->end_date)
                : now();

            $plan  = $data['plan'];
            $price = $this->resolvePrice($plan, $data['override_price'] ?? null, $data['can_override'] ?? false);
            $end   = $plan === 'monthly' ? $start->copy()->addMonth() : $start->copy()->addYear();

            $subscription = Subscription::create([
                'school_id'       => $school->id,
                'plan'            => $plan,
                'amount'          => $price,
                'start_date'      => $start,
                'end_date'        => $end,
                'active'          => true,
                'idempotency_key' => $data['idempotency_key'] ?? null,
            ]);

            $invoice = $this->createInvoiceAndPayment(
                subscription: $subscription,
                customerType: 'school',
                entity:       $school,
                plan:         $plan,
                price:        $price,
                start:        $start,
                end:          $end,
                data:         $data,
            );

            AuditService::record(
                action:  'subscription.renewed',
                target:  $school,
                old:     $latest ? ['plan' => $latest->plan, 'end_date' => $latest->end_date?->toDateString()] : null,
                new: [
                    'plan'           => $plan,
                    'amount'         => $price,
                    'start_date'     => $start->toDateString(),
                    'end_date'       => $end->toDateString(),
                    'invoice_number' => $invoice->invoice_number,
                ],
                description: "School subscription renewed: {$school->name} (New Plan: {$plan}, Invoice: {$invoice->invoice_number})",
                severity:    'info',
                metadata:    ['school_name' => $school->name, 'subscription_id' => $subscription->id, 'invoice_id' => $invoice->id],
            );

            return ['subscription' => $subscription, 'invoice' => $invoice];
        });
    }

    /**
     * Renew a student/user subscription.
     */
    public function renewStudent(Student $student, array $data): array
    {
        if (! empty($data['idempotency_key'])) {
            $existing = $this->findExistingByIdempotencyKey($data['idempotency_key']);
            if ($existing) {
                return ['subscription' => $existing->subscription, 'invoice' => $existing];
            }
        }

        return DB::transaction(function () use ($student, $data) {
            $today = now()->toDateString();
            $latest = Subscription::where('student_id', $student->id)
                ->where('active', true)
                ->orderBy('end_date', 'desc')
                ->first();

            $start = ($latest && $latest->end_date && $latest->end_date->toDateString() >= $today)
                ? Carbon::parse($latest->end_date)
                : now();

            $plan  = $data['plan'];
            $price = $this->resolvePrice($plan, $data['override_price'] ?? null, $data['can_override'] ?? false);
            $end   = $plan === 'monthly' ? $start->copy()->addMonth() : $start->copy()->addYear();

            $subscription = Subscription::create([
                'student_id'      => $student->id,
                'plan'            => $plan,
                'amount'          => $price,
                'start_date'      => $start,
                'end_date'        => $end,
                'active'          => true,
                'idempotency_key' => $data['idempotency_key'] ?? null,
            ]);

            $invoice = $this->createInvoiceAndPayment(
                subscription: $subscription,
                customerType: 'student',
                entity:       $student,
                plan:         $plan,
                price:        $price,
                start:        $start,
                end:          $end,
                data:         $data,
            );

            AuditService::record(
                action:  'subscription.renewed',
                target:  $student,
                old:     $latest ? ['plan' => $latest->plan, 'end_date' => $latest->end_date?->toDateString()] : null,
                new: [
                    'plan'           => $plan,
                    'amount'         => $price,
                    'start_date'     => $start->toDateString(),
                    'end_date'       => $end->toDateString(),
                    'invoice_number' => $invoice->invoice_number,
                ],
                description: "Student subscription renewed: {$student->first_name} {$student->last_name} (New Plan: {$plan}, Invoice: {$invoice->invoice_number})",
                severity:    'info',
                metadata:    ['student_id' => $student->id, 'subscription_id' => $subscription->id, 'invoice_id' => $invoice->id],
            );

            return ['subscription' => $subscription, 'invoice' => $invoice];
        });
    }

    // ── Internal Helpers ──────────────────────────────────────────────────────

    /**
     * Create an Invoice and its linked Payment inside an existing DB transaction.
     *
     * @param  School|Student  $entity
     */
    private function createInvoiceAndPayment(
        Subscription    $subscription,
        string          $customerType,
        School|Student  $entity,
        string          $plan,
        float           $price,
        Carbon          $start,
        Carbon          $end,
        array           $data,
    ): Invoice {
        $actorId = Auth::guard('sanctum')->id() ?? Auth::guard('api')->id() ?? Auth::id();

        // Snapshot customer info at the time of billing
        if ($customerType === 'school') {
            $customerName    = $entity->name;
            $customerEmail   = $entity->admin_email ?? null;
            $customerPhone   = null;
            $customerAddress = null;
        } else {
            $customerName    = trim("{$entity->first_name} {$entity->last_name}");
            $customerEmail   = $entity->email ?? null;
            $customerPhone   = $entity->phone ?? null;
            $customerAddress = null;
        }

        $invoiceNumber = $this->generateInvoiceNumber();
        $now           = now();
        $planLabel     = ucfirst($plan);

        $pricing = $this->getPlanPricingDetails($plan);
        $taxPercent = isset($data['tax_rate']) && $data['tax_rate'] !== null
            ? (float) $data['tax_rate']
            : (float) ($pricing['tax_percent'] ?? 0);

        if (abs($price - $pricing['final_price']) < 0.001 && abs($taxPercent - (float) ($pricing['tax_percent'] ?? 0)) < 0.001) {
            $subtotal = $pricing['subtotal'];
            $discount = $pricing['discount_amount'];
            $tax      = $pricing['tax_amount'];
            $total    = $pricing['final_price'];
        } elseif ($pricing['subtotal'] > 0 && $price < $pricing['subtotal']) {
            $subtotal = $pricing['subtotal'];
            $discount = max(0, round($subtotal - $price, 2));
            $tax      = $taxPercent > 0 ? round($price * ($taxPercent / 100), 2) : 0.00;
            $total    = round($price + $tax, 2);
        } else {
            $subtotal = $price;
            $discount = 0.00;
            $tax      = $taxPercent > 0 ? round($subtotal * ($taxPercent / 100), 2) : 0.00;
            $total    = round($subtotal + $tax, 2);
        }

        $invoice = Invoice::create([
            'invoice_number'       => $invoiceNumber,
            'subscription_id'      => $subscription->id,
            'customer_type'        => $customerType,
            'school_id'            => $customerType === 'school' ? $entity->id : null,
            'student_id'           => $customerType === 'student' ? $entity->id : null,
            'customer_name'        => $customerName,
            'customer_email'       => $customerEmail,
            'customer_phone'       => $customerPhone,
            'customer_address'     => $customerAddress,
            'description'          => "{$planLabel} subscription for {$customerName}",
            'plan'                 => $plan,
            'billing_period_start' => $start->toDateString(),
            'billing_period_end'   => $end->toDateString(),
            'subtotal'             => $subtotal,
            'discount'             => $discount,
            'tax'                  => $tax,
            'total'                => $total,
            'currency'             => 'USD',
            'status'               => 'paid',
            'issued_at'            => $now,
            'paid_at'              => $now,
            'created_by'           => $actorId,
            'idempotency_key'      => $data['idempotency_key'] ?? null,
        ]);

        Payment::create([
            'invoice_id'        => $invoice->id,
            'amount'            => $total,
            'currency'          => 'USD',
            'payment_method'    => $data['payment_method'],
            'payment_reference' => $data['payment_reference'] ?? null,
            'status'            => 'completed',
            'paid_at'           => $now,
            'recorded_by'       => $actorId,
            'notes'             => $data['notes'] ?? null,
        ]);

        // Audit invoice creation
        AuditService::record(
            action:      'invoice.created',
            target:      $invoice,
            new: [
                'invoice_number' => $invoiceNumber,
                'total'          => $price,
                'plan'           => $plan,
                'status'         => 'paid',
            ],
            description: "Invoice {$invoiceNumber} created for {$customerName}",
            severity:    'info',
        );

        return $invoice->load('payment');
    }

    // ── Deactivation & Cancellation ──────────────────────────────────────────

    /**
     * Deactivate / Terminate an active school subscription.
     */
    public function deactivateSchool(School $school, string $reason, bool $voidInvoice = false): array
    {
        return DB::transaction(function () use ($school, $reason, $voidInvoice) {
            $activeSubs = Subscription::where('school_id', $school->id)
                ->where('active', true)
                ->get();

            if ($activeSubs->isEmpty()) {
                throw new \RuntimeException('School does not have an active subscription to deactivate.');
            }

            $primarySub = $activeSubs->sortByDesc('end_date')->first();

            // Deactivate all active subscriptions for this school
            Subscription::where('school_id', $school->id)
                ->where('active', true)
                ->update(['active' => false]);

            $invoice = null;
            if ($voidInvoice) {
                $subIds = $activeSubs->pluck('id')->all();
                $linkedInvoice = Invoice::whereIn('subscription_id', $subIds)
                    ->where('status', '!=', 'void')
                    ->latest()
                    ->first();

                if (! $linkedInvoice) {
                    $linkedInvoice = Invoice::where('school_id', $school->id)
                        ->where('status', '!=', 'void')
                        ->latest()
                        ->first();
                }

                if ($linkedInvoice) {
                    $invoice = $this->voidInvoice($linkedInvoice, "Subscription terminated: {$reason}");
                }
            }

            AuditService::record(
                action:      'subscription.deactivated',
                target:      $school,
                old:         ['active' => true],
                new:         ['active' => false, 'reason' => $reason, 'void_invoice' => $voidInvoice],
                description: "School subscription deactivated: {$school->name}. Reason: {$reason}",
                severity:    'warning',
                metadata:    ['school_id' => $school->id, 'subscription_id' => $primarySub->id],
            );

            return [
                'subscription' => $primarySub->fresh(),
                'invoice'      => $invoice,
            ];
        });
    }

    /**
     * Deactivate / Terminate an active student subscription.
     */
    public function deactivateStudent(Student $student, string $reason, bool $voidInvoice = false): array
    {
        return DB::transaction(function () use ($student, $reason, $voidInvoice) {
            $activeSubs = Subscription::where('student_id', $student->id)
                ->where('active', true)
                ->get();

            if ($activeSubs->isEmpty()) {
                throw new \RuntimeException('Student does not have an active subscription to deactivate.');
            }

            $primarySub = $activeSubs->sortByDesc('end_date')->first();

            // Deactivate all active subscriptions for this student
            Subscription::where('student_id', $student->id)
                ->where('active', true)
                ->update(['active' => false]);

            $invoice = null;
            if ($voidInvoice) {
                $subIds = $activeSubs->pluck('id')->all();
                $linkedInvoice = Invoice::whereIn('subscription_id', $subIds)
                    ->where('status', '!=', 'void')
                    ->latest()
                    ->first();

                if (! $linkedInvoice) {
                    $linkedInvoice = Invoice::where('student_id', $student->id)
                        ->where('status', '!=', 'void')
                        ->latest()
                        ->first();
                }

                if ($linkedInvoice) {
                    $invoice = $this->voidInvoice($linkedInvoice, "Subscription terminated: {$reason}");
                }
            }

            AuditService::record(
                action:      'subscription.deactivated',
                target:      $student,
                old:         ['active' => true],
                new:         ['active' => false, 'reason' => $reason, 'void_invoice' => $voidInvoice],
                description: "Student subscription deactivated: {$student->first_name} {$student->last_name}. Reason: {$reason}",
                severity:    'warning',
                metadata:    ['student_id' => $student->id, 'subscription_id' => $primarySub->id],
            );

            return [
                'subscription' => $primarySub->fresh(),
                'invoice'      => $invoice,
            ];
        });
    }

    // ── Void ──────────────────────────────────────────────────────────────────

    /**
     * Void an invoice. The original record is preserved with status = 'void'.
     */
    public function voidInvoice(Invoice $invoice, string $reason, bool $deactivateSubscription = false): Invoice
    {
        if ($invoice->isVoid()) {
            throw new \RuntimeException('Invoice is already voided.');
        }

        $actorId = Auth::guard('api')->id();

        $invoice->update([
            'status'      => 'void',
            'void_reason' => $reason,
            'voided_at'   => now(),
            'voided_by'   => $actorId,
        ]);

        if ($deactivateSubscription) {
            if ($invoice->subscription_id) {
                Subscription::where('id', $invoice->subscription_id)->update(['active' => false]);
            }
            if ($invoice->student_id) {
                Subscription::where('student_id', $invoice->student_id)
                    ->where('active', true)
                    ->update(['active' => false]);
            } elseif ($invoice->school_id) {
                Subscription::where('school_id', $invoice->school_id)
                    ->where('active', true)
                    ->update(['active' => false]);
            }

            AuditService::record(
                action:      'subscription.deactivated',
                target:      $invoice,
                old:         ['active' => true],
                new:         ['active' => false, 'reason' => "Invoice {$invoice->invoice_number} voided: {$reason}"],
                description: "Subscriptions deactivated because linked invoice {$invoice->invoice_number} was voided.",
                severity:    'warning',
            );
        }

        AuditService::record(
            action:      'invoice.voided',
            target:      $invoice,
            old:         ['status' => 'paid'],
            new:         ['status' => 'void', 'void_reason' => $reason],
            description: "Invoice {$invoice->invoice_number} voided. Reason: {$reason}",
            severity:    'warning',
        );

        return $invoice->fresh();
    }
}
