<?php

namespace App\Http\Controllers\School\V01;

use App\Http\Resources\Admin\V01\Subscription\InvoiceResource;
use App\Models\Invoice;
use App\Models\School;
use App\Models\Subscription;
use App\Services\AuditService;
use Barryvdh\DomPDF\Facade\Pdf;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;

class SchoolBillingController extends Controller
{
    /**
     * Resolve the authenticated school and verify School Admin authorization.
     *
     * @return array{0: ?School, 1: ?string, 2: int}
     */
    protected function resolveAuthorizedSchool(Request $request): array
    {
        $user = $request->user();
        if (!$user) {
            return [null, 'Unauthenticated.', 401];
        }

        $schoolId = (int) ($user->school_id ?? 0);

        // If user has no school_id on account, allow super-admin with school_id query parameter
        if ($schoolId <= 0 && $request->filled('school_id')) {
            if ($user->hasRole('super-admin')) {
                $schoolId = (int) $request->input('school_id');
            }
        }

        if ($schoolId <= 0) {
            return [null, 'No school associated with this account.', 403];
        }

        $school = School::find($schoolId);
        if (!$school) {
            return [null, 'School not found.', 404];
        }

        // Authorization check: match school's admin_email, school-admin role, or super-admin
        $userEmail = strtolower(trim((string) $user->email));
        $adminEmail = strtolower(trim((string) ($school->admin_email ?? '')));
        $isSchoolAdmin = ($adminEmail && $userEmail === $adminEmail)
            || $user->hasRole('school-admin')
            || $user->hasRole('super-admin')
            || $user->can('billing.view');

        if (!$isSchoolAdmin) {
            return [null, 'Access denied. Only school administrators can view billing.', 403];
        }

        return [$school, null, 200];
    }

    /**
     * GET /api/school/billing
     *
     * Return read-only subscription and billing history for the authenticated school.
     */
    public function index(Request $request): JsonResponse
    {
        [$school, $error, $code] = $this->resolveAuthorizedSchool($request);
        if (!$school) {
            return $this->returnError($error, $code);
        }

        $now = Carbon::now();

        // Eager load related invoice and its payment record
        $subscriptions = Subscription::where('school_id', $school->id)
            ->with(['invoice.payment'])
            ->orderBy('end_date', 'desc')
            ->orderBy('id', 'desc')
            ->get();

        // Determine the currently active subscription
        $activeSub = $subscriptions->first(function ($s) use ($now) {
            return (bool) $s->active && $s->start_date <= $now && $s->end_date >= $now;
        });

        $currentSubscription = null;
        if ($activeSub) {
            $daysLeft = (int) $now->diffInDays($activeSub->end_date, false);
            $currentSubscription = [
                'id'           => $activeSub->id,
                'plan'         => $activeSub->plan,
                'plan_name'    => ucfirst($activeSub->plan) . ' Plan',
                'amount'       => (float) $activeSub->amount,
                'currency'     => $activeSub->invoice?->currency ?? 'USD',
                'status'       => 'active',
                'status_label' => 'Active',
                'is_active'    => true,
                'start_date'   => $activeSub->start_date?->toDateString(),
                'end_date'     => $activeSub->end_date?->toDateString(),
                'days_left'    => max(0, $daysLeft),
                'has_invoice'  => (bool) $activeSub->invoice,
                'invoice'      => $activeSub->invoice ? [
                    'id'             => $activeSub->invoice->id,
                    'invoice_number' => $activeSub->invoice->invoice_number,
                    'status'         => $activeSub->invoice->status,
                    'total'          => (float) $activeSub->invoice->total,
                    'currency'       => $activeSub->invoice->currency,
                    'issued_at'      => $activeSub->invoice->issued_at?->toIso8601String(),
                    'paid_at'        => $activeSub->invoice->paid_at?->toIso8601String(),
                    'has_pdf'        => (bool) $activeSub->invoice->pdf_path,
                ] : null,
            ];
        }

        // Format history of all subscriptions
        $history = $subscriptions->map(function ($sub) use ($now) {
            $isCurrentlyActive = (bool) $sub->active && $sub->start_date <= $now && $sub->end_date >= $now;
            $status = $isCurrentlyActive
                ? 'active'
                : ($sub->end_date < $now ? 'expired' : ($sub->active ? 'upcoming' : 'inactive'));

            return [
                'id'           => $sub->id,
                'plan'         => $sub->plan,
                'plan_name'    => ucfirst($sub->plan) . ' Plan',
                'amount'       => (float) $sub->amount,
                'currency'     => $sub->invoice?->currency ?? 'USD',
                'status'       => $status,
                'status_label' => ucfirst($status),
                'start_date'   => $sub->start_date?->toDateString(),
                'end_date'     => $sub->end_date?->toDateString(),
                'period_label' => ($sub->start_date?->format('d M Y') ?? '—') . ' - ' . ($sub->end_date?->format('d M Y') ?? '—'),
                'has_invoice'  => (bool) $sub->invoice,
                'invoice'      => $sub->invoice ? [
                    'id'             => $sub->invoice->id,
                    'invoice_number' => $sub->invoice->invoice_number,
                    'status'         => $sub->invoice->status,
                    'total'          => (float) $sub->invoice->total,
                    'currency'       => $sub->invoice->currency,
                    'issued_at'      => $sub->invoice->issued_at?->toIso8601String(),
                    'paid_at'        => $sub->invoice->paid_at?->toIso8601String(),
                    'has_pdf'        => (bool) $sub->invoice->pdf_path,
                    'payment'        => $sub->invoice->payment ? [
                        'id'                => $sub->invoice->payment->id,
                        'payment_method'    => $sub->invoice->payment->payment_method,
                        'payment_reference' => $sub->invoice->payment->payment_reference,
                        'paid_at'           => $sub->invoice->payment->paid_at?->toIso8601String(),
                    ] : null,
                ] : null,
            ];
        });

        $this->setResult('school', [
            'id'          => $school->id,
            'name'        => $school->name,
            'admin_email' => $school->admin_email,
        ]);
        $this->setResult('current_subscription', $currentSubscription);
        $this->setResult('history', $history);

        return $this->returnResponse();
    }

    /**
     * GET /api/school/billing/invoices/{id}
     *
     * View detailed invoice information for an invoice belonging to the authenticated school.
     */
    public function showInvoice(Request $request, $id): JsonResponse
    {
        [$school, $error, $code] = $this->resolveAuthorizedSchool($request);
        if (!$school) {
            return $this->returnError($error, $code);
        }

        $invoice = Invoice::with(['payment', 'subscription', 'school'])->find($id);
        if (!$invoice) {
            return $this->returnError('Invoice not found.', 404);
        }

        // Strict ownership enforcement
        if ((int) $invoice->school_id !== (int) $school->id || $invoice->customer_type !== 'school') {
            return $this->returnError('You do not have permission to view this invoice.', 403);
        }

        AuditService::record(
            action:      'invoice.viewed',
            target:      $invoice,
            description: "Invoice {$invoice->invoice_number} viewed by School Admin ({$school->name})",
            severity:    'info',
            metadata:    ['school_id' => $school->id, 'invoice_id' => $invoice->id],
        );

        $this->setResult('invoice', new InvoiceResource($invoice));
        return $this->returnResponse();
    }

    /**
     * GET /api/school/billing/invoices/{id}/pdf
     *
     * Download or view the official invoice PDF for an invoice belonging to the authenticated school.
     */
    public function downloadInvoicePdf(Request $request, $id): Response|JsonResponse
    {
        [$school, $error, $code] = $this->resolveAuthorizedSchool($request);
        if (!$school) {
            return $this->returnError($error, $code);
        }

        $invoice = Invoice::with(['payment', 'subscription', 'school'])->find($id);
        if (!$invoice) {
            return $this->returnError('Invoice not found.', 404);
        }

        // Strict ownership enforcement
        if ((int) $invoice->school_id !== (int) $school->id || $invoice->customer_type !== 'school') {
            return $this->returnError('You do not have permission to download this invoice.', 403);
        }

        AuditService::record(
            action:      'invoice.downloaded',
            target:      $invoice,
            description: "Invoice {$invoice->invoice_number} PDF downloaded by School Admin ({$school->name})",
            severity:    'info',
            metadata:    ['school_id' => $school->id, 'invoice_id' => $invoice->id],
        );

        // If a cached PDF exists on disk, serve it directly
        if ($invoice->pdf_path && Storage::disk('local')->exists($invoice->pdf_path)) {
            $file = Storage::disk('local')->get($invoice->pdf_path);
            $hash = hash('sha256', $file);

            if ($invoice->pdf_sha256 && $hash !== $invoice->pdf_sha256) {
                Log::warning('Invoice PDF hash mismatch during school download', ['invoice_id' => $invoice->id]);
            }

            return response($file, 200, [
                'Content-Type'        => 'application/pdf',
                'Content-Disposition' => 'inline; filename="' . $invoice->invoice_number . '.pdf"',
            ]);
        }

        // Generate PDF on the fly using existing Blade template
        $pdf = Pdf::loadView('invoices.invoice', ['invoice' => $invoice])
            ->setPaper('a4', 'portrait');

        $pdfContent = $pdf->output();

        // Cache PDF for future downloads
        $path = 'private/invoices/' . $invoice->invoice_number . '.pdf';
        Storage::disk('local')->put($path, $pdfContent);
        $sha256 = hash('sha256', $pdfContent);

        $invoice->update([
            'pdf_path'   => $path,
            'pdf_sha256' => $sha256,
        ]);

        return response($pdfContent, 200, [
            'Content-Type'        => 'application/pdf',
            'Content-Disposition' => 'inline; filename="' . $invoice->invoice_number . '.pdf"',
        ]);
    }
}
