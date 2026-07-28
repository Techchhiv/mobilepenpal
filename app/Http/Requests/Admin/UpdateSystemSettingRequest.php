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

        if ($this->route('key') === 'feature_locks') {
            $rules['value.enabled'] = ['required', 'boolean'];
            $rules['value.mini_game_free_daily_limit'] = ['required', 'integer', 'min:0'];
            $rules['value.ai_writing_free_char_limit'] = ['required', 'integer', 'min:1'];
            $rules['value.learning_free_stage_limit'] = ['nullable', 'integer', 'min:0'];
        }

        return $rules;
    }
}
