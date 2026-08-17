<?php

namespace App\Http\Requests\Admin\Subscription;

use Illuminate\Foundation\Http\FormRequest;

class ActivateSubscriptionRequest extends FormRequest
{
    public function authorize(): bool
    {
        // Authorization is handled by route middleware
        return true;
    }

    public function rules(): array
    {
        return [
            'plan'              => 'required|in:monthly,yearly',
            'amount'            => 'nullable|numeric|min:0',
            'override_price'    => 'nullable|numeric|min:0',
            'tax_rate'          => 'nullable|numeric|between:0,100',
            'payment_method'    => 'required|in:cash,bank_transfer,other',
            'payment_reference' => 'nullable|string|max:255',
            'notes'             => 'nullable|string|max:1000',
            'idempotency_key'   => 'required|uuid',
        ];
    }

    public function messages(): array
    {
        return [
            'idempotency_key.required' => 'A unique request key is required to prevent duplicate submissions.',
            'idempotency_key.uuid'     => 'The request key must be a valid UUID.',
        ];
    }

    /**
     * Prepare validated data for the billing service.
     */
    public function billingData(): array
    {
        $customPrice = $this->filled('amount')
            ? $this->input('amount')
            : ($this->filled('override_price') ? $this->input('override_price') : null);

        return [
            'plan'              => $this->plan,
            'payment_method'    => $this->payment_method,
            'payment_reference' => $this->payment_reference,
            'notes'             => $this->notes,
            'idempotency_key'   => $this->idempotency_key,
            'override_price'    => $customPrice !== null ? (float) $customPrice : null,
            'tax_rate'          => $this->filled('tax_rate') ? (float) $this->input('tax_rate') : null,
            'can_override'      => true,
        ];
    }
}
