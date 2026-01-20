<?php

namespace App\Http\Requests\Admin\Stage;

use Illuminate\Foundation\Http\FormRequest;

class UpdateStageRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'name'        => ['sometimes', 'required', 'string', 'max:255'],
            'description' => ['sometimes', 'nullable', 'string'],
            'instruction' => ['sometimes', 'nullable', 'string'],
            'max_stars'   => ['sometimes', 'integer', 'min:1', 'max:10'],
            'order_index' => ['sometimes', 'integer', 'min:1'],
            'is_active'   => ['sometimes', 'boolean'],
        ];
    }
}
