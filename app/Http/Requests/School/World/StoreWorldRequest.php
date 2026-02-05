<?php

namespace App\Http\Requests\School\World;

use Illuminate\Foundation\Http\FormRequest;

class StoreWorldRequest extends FormRequest
{
    public function rules()
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'name_en' => ['required', 'string', 'max:255'],

            'description' => ['nullable', 'string'],
            'description_en' => ['nullable', 'string'],

            'is_active' => ['sometimes', 'boolean'],
            'is_unlocked_by_default' => ['sometimes', 'boolean'],
        ];
    }
}
