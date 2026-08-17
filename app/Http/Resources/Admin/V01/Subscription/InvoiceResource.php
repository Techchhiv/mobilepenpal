<?php

namespace App\Http\Resources\Admin\V01\Subscription;

use Illuminate\Http\Resources\Json\JsonResource;

class InvoiceResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id'                   => $this->id,
            'invoice_number'       => $this->invoice_number,
            'status'               => $this->status,

            // Customer snapshot
            'customer_type'        => $this->customer_type,
            'customer_name'        => $this->customer_name,
            'customer_email'       => $this->customer_email,
            'customer_phone'       => $this->customer_phone,
            'customer_address'     => $this->customer_address,

            // Related IDs for frontend navigation
            'school_id'            => $this->school_id,
            'student_id'           => $this->student_id,
            'subscription_id'      => $this->subscription_id,

            // Plan
            'plan'                 => $this->plan,
            'description'          => $this->description,
            'billing_period_start' => $this->billing_period_start?->toDateString(),
            'billing_period_end'   => $this->billing_period_end?->toDateString(),

            // Financials
            'subtotal'             => (float) $this->subtotal,
            'discount'             => (float) $this->discount,
            'tax'                  => (float) $this->tax,
            'total'                => (float) $this->total,
            'currency'             => $this->currency,

            // Dates
            'issued_at'            => $this->issued_at?->toIso8601String(),
            'paid_at'              => $this->paid_at?->toIso8601String(),
            'voided_at'            => $this->voided_at?->toIso8601String(),
            'void_reason'          => $this->void_reason,

            // Who created / voided
            'created_by'           => $this->created_by,
            'voided_by'            => $this->voided_by,

            // PDF availability
            'has_pdf'              => (bool) $this->pdf_path,

            // Payment info (eager loaded)
            'payment' => $this->when($this->relationLoaded('payment') && $this->payment, fn () => [
                'id'                => $this->payment->id,
                'payment_method'    => $this->payment->payment_method,
                'payment_reference' => $this->payment->payment_reference,
                'amount'            => (float) $this->payment->amount,
                'currency'          => $this->payment->currency,
                'paid_at'           => $this->payment->paid_at?->toIso8601String(),
                'notes'             => $this->payment->notes,
            ]),

            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
