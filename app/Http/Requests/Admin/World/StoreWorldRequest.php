<?php

namespace App\Http\Requests\Admin\World;

use Illuminate\Foundation\Http\FormRequest;

class StoreWorldRequest extends FormRequest
{
    public function rules()
    {
        return [
            'audience' => ['required', 'in:public,schools,assigned'],
            'school_ids' => ['nullable', 'array'],
            'school_ids.*' => ['integer', 'exists:schools,id'],

            'name' => ['required', 'string', 'max:255'],
            'name_en' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'description_en' => ['nullable', 'string'],

            'is_active' => ['nullable', 'boolean'],
            'is_premium' => ['nullable', 'boolean'],
            'is_unlocked_by_default' => ['nullable', 'boolean'],
            'order_index' => ['nullable', 'integer', 'min:1'],
        ];
    }
}
