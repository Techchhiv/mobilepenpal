<?php

namespace App\Http\Requests\School\Level;

use Illuminate\Foundation\Http\FormRequest;

class UpdateLevelRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'name'                   => ['sometimes', 'required', 'string', 'max:255'],
            'description'            => ['nullable', 'string'],
            'name_en'                   => ['sometimes', 'required', 'string', 'max:255'],
            'description_en'            => ['nullable', 'string'],
            'is_active'              => ['nullable', 'boolean'],
            'is_unlocked_by_default' => ['nullable', 'boolean'],
        ];
    }
}
