<?php

namespace App\Http\Requests\Admin\Subscription;

use Illuminate\Foundation\Http\FormRequest;

class DeactivateSubscriptionRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'reason'       => 'required|string|max:500',
            'void_invoice' => 'nullable|boolean',
        ];
    }

    public function messages(): array
    {
        return [
            'reason.required' => 'A reason for deactivating the subscription is required for the audit trail.',
        ];
    }
}
