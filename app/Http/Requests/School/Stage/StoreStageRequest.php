<?php

namespace App\Http\Requests\School\Stage;

use Illuminate\Foundation\Http\FormRequest;

class StoreStageRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'name'        => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'name_en'        => ['required', 'string', 'max:255'],
            'description_en' => ['nullable', 'string'],
            'order_index' => ['nullable', 'integer', 'min:1'],
            'is_active'   => ['nullable', 'boolean'],
        ];
    }
}
