<?php

namespace App\Http\Controllers\School\V01;

use App\Http\Controllers\Controller;
use App\Models\Invoice;
use App\Models\Subscription;
use App\Models\SystemSetting;
use Barryvdh\DomPDF\Facade\Pdf;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class SchoolSubscriptionController extends Controller
{
    /**
     * GET /api/school/subscription
     * Return current subscription summary, history, and invoices for the authenticated school admin's school.
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

        $today = Carbon::today();
        $todayStr = $today->toDateString();

        // 1. Current / active subscription
        $activeSubscription = Subscription::where('school_id', $schoolId)
            ->where('active', true)
            ->where('start_date', '<=', $todayStr)
            ->where('end_date', '>=', $todayStr)
            ->orderBy('end_date', 'desc')
            ->first();

        if (!$activeSubscription) {
            $activeSubscription = Subscription::where('school_id', $schoolId)
                ->where('active', true)
                ->where('end_date', '>=', $todayStr)
                ->orderBy('end_date', 'desc')
                ->first();
        }

        $latestSubscription = Subscription::where('school_id', $schoolId)
            ->orderBy('end_date', 'desc')
            ->first();

        if ($activeSubscription) {
            $endDate = Carbon::parse($activeSubscription->end_date)->startOfDay();
            $daysLeft = max(0, (int) $today->diffInDays($endDate, false));
            if ($daysLeft <= 7) {
                $status = 'critical';
            } elseif ($daysLeft <= 30) {
                $status = 'expiring_soon';
            } else {
                $status = 'active';
            }

            $currentSubscription = [
                'id' => $activeSubscription->id,
                'has_subscription' => true,
                'is_active' => true,
                'is_expired' => false,
                'status' => $status,
                'plan' => $activeSubscription->plan,
                'amount' => $activeSubscription->amount,
                'start_date' => $activeSubscription->start_date ? $activeSubscription->start_date->toDateString() : null,
                'end_date' => $activeSubscription->end_date ? $activeSubscription->end_date->toDateString() : null,
                'days_left' => $daysLeft,
            ];
        } elseif ($latestSubscription) {
            $endDate = Carbon::parse($latestSubscription->end_date)->startOfDay();
            $isExpired = ($endDate < $today) || !$latestSubscription->active;
            $currentSubscription = [
                'id' => $latestSubscription->id,
                'has_subscription' => true,
                'is_active' => false,
                'is_expired' => $isExpired,
                'status' => $isExpired ? 'expired' : 'inactive',
                'plan' => $latestSubscription->plan,
                'amount' => $latestSubscription->amount,
                'start_date' => $latestSubscription->start_date ? $latestSubscription->start_date->toDateString() : null,
                'end_date' => $latestSubscription->end_date ? $latestSubscription->end_date->toDateString() : null,
                'days_left' => 0,
            ];
        } else {
            $currentSubscription = [
                'id' => null,
                'has_subscription' => false,
                'is_active' => false,
                'is_expired' => false,
                'status' => 'none',
                'plan' => null,
                'amount' => null,
                'start_date' => null,
                'end_date' => null,
                'days_left' => 0,
            ];
        }

        // 2. Subscription History
        $subscriptions = Subscription::where('school_id', $schoolId)
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(function ($sub) use ($today) {
                $endDate = $sub->end_date ? Carbon::parse($sub->end_date)->startOfDay() : null;
                $isExpired = ($endDate && $endDate < $today) || !$sub->active;
                return [
                    'id' => $sub->id,
                    'plan' => $sub->plan,
                    'amount' => $sub->amount,
                    'start_date' => $sub->start_date ? $sub->start_date->toDateString() : null,
                    'end_date' => $sub->end_date ? $sub->end_date->toDateString() : null,
                    'active' => (bool) $sub->active,
                    'is_expired' => $isExpired,
                    'status' => $sub->active && !$isExpired ? 'active' : ($isExpired ? 'expired' : 'inactive'),
                    'created_at' => $sub->created_at ? $sub->created_at->toIso8601String() : null,
                ];
            });

        // 3. Invoices
        $invoices = Invoice::where('school_id', $schoolId)
            ->with('payment')
            ->orderBy('issued_at', 'desc')
            ->get()
            ->map(function ($inv) {
                return [
                    'id' => $inv->id,
                    'invoice_number' => $inv->invoice_number,
                    'plan' => $inv->plan,
                    'description' => $inv->description,
                    'billing_period_start' => $inv->billing_period_start ? $inv->billing_period_start->toDateString() : null,
                    'billing_period_end' => $inv->billing_period_end ? $inv->billing_period_end->toDateString() : null,
                    'subtotal' => $inv->subtotal,
                    'discount' => $inv->discount,
                    'tax' => $inv->tax,
                    'total' => $inv->total,
                    'currency' => $inv->currency,
                    'status' => $inv->status,
                    'issued_at' => $inv->issued_at ? $inv->issued_at->toIso8601String() : null,
                    'paid_at' => $inv->paid_at ? $inv->paid_at->toIso8601String() : null,
                    'payment' => $inv->payment ? [
                        'method' => $inv->payment->payment_method ?? $inv->payment->method ?? 'cash',
                        'reference' => $inv->payment->payment_reference ?? $inv->payment->reference ?? null,
                        'paid_at' => $inv->payment->paid_at ? $inv->payment->paid_at->toIso8601String() : null,
                    ] : null,
                ];
            });

        // 4. Support Contact
        $setting = SystemSetting::find('subscription');
        $settingVal = $setting ? (is_array($setting->value) ? $setting->value : json_decode($setting->value, true)) : [];
        $supportContact = [
            'email' => $settingVal['contact_email'] ?? 'info@khmerpenpal.com',
            'phone' => $settingVal['contact_phone'] ?? '+855 935 248 60',
        ];

        return response()->json([
            'success' => true,
            'data' => [
                'current_subscription' => $currentSubscription,
                'subscriptions' => $subscriptions,
                'invoices' => $invoices,
                'support_contact' => $supportContact,
            ],
        ]);
    }

    /**
     * GET /api/school/invoices/{id}
     * Returns invoice details strictly scoped to authenticated user's school.
     */
    public function showInvoice(Request $request, $id)
    {
        $schoolId = $request->user()->school_id;

        if (!$schoolId) {
            return response()->json([
                'success' => false,
                'message' => 'No school associated with this account.',
            ], 403);
        }

        $invoice = Invoice::where('school_id', $schoolId)
            ->with(['payment', 'subscription'])
            ->find($id);

        if (!$invoice) {
            return response()->json([
                'success' => false,
                'message' => 'Invoice not found.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => [
                'invoice' => $invoice,
            ],
        ]);
    }

    /**
     * GET /api/school/invoices/{id}/pdf
     * Generate / serve invoice PDF strictly scoped to authenticated user's school.
     */
    public function downloadInvoicePdf(Request $request, $id)
    {
        $schoolId = $request->user()->school_id;

        if (!$schoolId) {
            return response()->json([
                'success' => false,
                'message' => 'No school associated with this account.',
            ], 403);
        }

        $invoice = Invoice::where('school_id', $schoolId)
            ->with(['payment', 'subscription'])
            ->find($id);

        if (!$invoice) {
            return response()->json([
                'success' => false,
                'message' => 'Invoice not found.',
            ], 404);
        }

        // If cached PDF exists, serve it
        if ($invoice->pdf_path && Storage::disk('local')->exists($invoice->pdf_path)) {
            $file = Storage::disk('local')->get($invoice->pdf_path);
            return response($file, 200, [
                'Content-Type' => 'application/pdf',
                'Content-Disposition' => 'inline; filename="' . $invoice->invoice_number . '.pdf"',
            ]);
        }

        // Otherwise generate on the fly
        $pdf = Pdf::loadView('invoices.invoice', ['invoice' => $invoice])
            ->setPaper('a4', 'portrait');

        $pdfContent = $pdf->output();

        $path = 'private/invoices/' . $invoice->invoice_number . '.pdf';
        Storage::disk('local')->put($path, $pdfContent);
        $sha256 = hash('sha256', $pdfContent);

        $invoice->update([
            'pdf_path' => $path,
            'pdf_sha256' => $sha256,
        ]);

        return response($pdfContent, 200, [
            'Content-Type' => 'application/pdf',
            'Content-Disposition' => 'inline; filename="' . $invoice->invoice_number . '.pdf"',
        ]);
    }
}
