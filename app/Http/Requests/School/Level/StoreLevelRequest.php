<?php

namespace App\Http\Requests\School\Level;

use Illuminate\Foundation\Http\FormRequest;

class StoreLevelRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'name'                   => ['required', 'string', 'max:255'],
            'description'            => ['nullable', 'string'],
            'background_image'       => ['nullable', 'string', 'max:2048'],
            'order_index'            => ['nullable', 'integer', 'min:1'],
            'is_active'              => ['nullable', 'boolean'],
            'is_unlocked_by_default' => ['nullable', 'boolean'],
        ];
    }
}
