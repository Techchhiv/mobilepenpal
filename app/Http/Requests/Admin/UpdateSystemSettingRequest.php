<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;

class UpdateSystemSettingRequest extends FormRequest
{
    public function rules(): array
    {
        $rules = [
            'value' => ['required', 'array'],
        ];

        if ($this->route('key') === 'subscription') {
            $rules['value.price'] = ['required', 'numeric', 'min:0'];
            $rules['value.discount'] = ['required', 'integer', 'between:0,100'];
            $rules['value.billing_cycle'] = ['required', 'in:month,year'];
            $rules['value.contact_phone'] = ['required', 'string'];
            $rules['value.contact_email'] = ['required', 'email'];
        }

        return $rules;
    }
}
