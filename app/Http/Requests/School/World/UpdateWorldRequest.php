<?php

namespace App\Http\Requests\School\World;

use Illuminate\Foundation\Http\FormRequest;

class UpdateWorldRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'name' => ['sometimes', 'required', 'string', 'max:255'],
            'name_en' => ['sometimes', 'required', 'string', 'max:255'],

            'description' => ['sometimes', 'nullable', 'string'],
            'description_en' => ['sometimes', 'nullable', 'string'],

            'is_active' => ['sometimes', 'boolean'],
            'is_premium' => ['sometimes', 'boolean'],
            'is_unlocked_by_default' => ['sometimes', 'boolean'],
        ];
    }
}
