<?php

namespace App\Http\Requests\Admin\Stage;

use Illuminate\Foundation\Http\FormRequest;

class StoreStageRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'name'        => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'instruction' => ['nullable', 'string'],
            'max_stars'   => ['nullable', 'integer', 'min:1', 'max:10'],
            'order_index' => ['nullable', 'integer', 'min:1'],
            'is_active'   => ['nullable', 'boolean'],
        ];
    }
}
