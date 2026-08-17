<?php

namespace App\Http\Controllers\Admin\V01;

use App\Http\Requests\Admin\Subscription\VoidInvoiceRequest;
use App\Http\Resources\Admin\V01\Subscription\InvoiceResource;
use App\Models\Invoice;
use App\Services\AuditService;
use App\Services\SubscriptionBillingService;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class InvoiceController extends Controller
{
    public function __construct(protected SubscriptionBillingService $billing) {}

    /**
     * GET /api/admin/invoices
     * Paginated invoice list with optional filters.
     */
    public function index(Request $request)
    {
        $request->validate([
            'invoice_number' => 'nullable|string|max:30',
            'customer_name'  => 'nullable|string|max:100',
            'customer_type'  => 'nullable|in:school,student',
            'status'         => 'nullable|in:issued,paid,void',
            'plan'           => 'nullable|in:monthly,yearly',
            'date_from'      => 'nullable|date',
            'date_to'        => 'nullable|date|after_or_equal:date_from',
            'per_page'       => 'nullable|integer|min:5|max:100',
        ]);

        $query = Invoice::with('payment')
            ->orderBy('issued_at', 'desc');

        if ($request->filled('invoice_number')) {
            $query->where('invoice_number', 'like', '%' . $request->invoice_number . '%');
        }
        if ($request->filled('customer_name')) {
            $query->where('customer_name', 'like', '%' . $request->customer_name . '%');
        }
        if ($request->filled('customer_type')) {
            $query->where('customer_type', $request->customer_type);
        }
        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }
        if ($request->filled('plan')) {
            $query->where('plan', $request->plan);
        }
        if ($request->filled('date_from')) {
            $query->where('issued_at', '>=', $request->date_from);
        }
        if ($request->filled('date_to')) {
            $query->where('issued_at', '<=', $request->date_to . ' 23:59:59');
        }

        $invoices = $query->paginate($request->input('per_page', 20));

        return InvoiceResource::collection($invoices);
    }

    /**
     * GET /api/admin/invoices/{invoice}
     * Invoice detail.
     */
    public function show(Invoice $invoice)
    {
        $invoice->load(['payment', 'subscription']);

        AuditService::record(
            action:      'invoice.viewed',
            target:      $invoice,
            description: "Invoice {$invoice->invoice_number} viewed",
            severity:    'info',
        );

        $this->setResult('invoice', new InvoiceResource($invoice));
        return $this->returnResponse();
    }

    /**
     * GET /api/admin/invoices/{invoice}/pdf
     * Generate and serve invoice PDF (private, authenticated).
     */
    public function downloadPdf(Invoice $invoice)
    {
        AuditService::record(
            action:      'invoice.downloaded',
            target:      $invoice,
            description: "Invoice {$invoice->invoice_number} PDF downloaded",
            severity:    'info',
        );

        $invoice->load(['payment', 'subscription']);

        // If a cached PDF exists on disk, serve it directly and verify hash
        if ($invoice->pdf_path && Storage::disk('local')->exists($invoice->pdf_path)) {
            $file = Storage::disk('local')->get($invoice->pdf_path);
            $hash = hash('sha256', $file);

            // Integrity check
            if ($invoice->pdf_sha256 && $hash !== $invoice->pdf_sha256) {
                \Log::warning("Invoice PDF hash mismatch", ['invoice_id' => $invoice->id]);
            }

            return response($file, 200, [
                'Content-Type'        => 'application/pdf',
                'Content-Disposition' => 'inline; filename="' . $invoice->invoice_number . '.pdf"',
            ]);
        }

        // Generate PDF on the fly
        $pdf = Pdf::loadView('invoices.invoice', ['invoice' => $invoice])
            ->setPaper('a4', 'portrait');

        $pdfContent = $pdf->output();

        // Store for future downloads
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

    /**
     * POST /api/admin/invoices/{invoice}/void
     * Void an invoice (soft — record is preserved, status changes to 'void').
     */
    public function void(VoidInvoiceRequest $request, Invoice $invoice)
    {
        if ($invoice->isVoid()) {
            return $this->returnError('Invoice is already voided.', 422);
        }

        $voided = $this->billing->voidInvoice(
            $invoice,
            $request->reason,
            (bool) $request->boolean('deactivate_subscription')
        );

        $this->setMessage('Invoice voided successfully.');
        $this->setResult('invoice', new InvoiceResource($voided->load('payment')));
        return $this->returnResponse();
    }

    /**
     * GET /api/admin/invoices/prices
     * Return the backend-authoritative plan prices for display in the React modal.
     */
    public function prices()
    {
        $monthly = $this->billing->getPlanPricingDetails('monthly');
        $yearly  = $this->billing->getPlanPricingDetails('yearly');

        $this->setResult('prices', [
            'monthly'  => $monthly['final_price'],
            'yearly'   => $yearly['final_price'],
            'details'  => [
                'monthly' => $monthly,
                'yearly'  => $yearly,
            ],
            'currency' => 'USD',
        ]);
        return $this->returnResponse();
    }
}
