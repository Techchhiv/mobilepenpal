<?php

namespace App\Http\Requests\School\Stage;

use Illuminate\Foundation\Http\FormRequest;

class UpdateStageRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'name'        => ['sometimes', 'required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'instruction' => ['nullable', 'string'],
            'max_stars'   => ['nullable', 'integer', 'min:1', 'max:10'],
            'is_active'   => ['nullable', 'boolean'],
        ];
    }
}
