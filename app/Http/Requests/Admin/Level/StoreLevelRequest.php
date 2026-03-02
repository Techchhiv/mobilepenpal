<?php

namespace App\Http\Requests\Admin\Level;

use Illuminate\Foundation\Http\FormRequest;

class StoreLevelRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'name_en' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'description_en' => ['nullable', 'string'],

            'order_index' => ['nullable', 'integer', 'min:1'],
            'is_active' => ['nullable', 'boolean'],
            'is_premium' => ['nullable', 'boolean'],
            'is_unlocked_by_default' => ['nullable', 'boolean'],
        ];
    }
}
