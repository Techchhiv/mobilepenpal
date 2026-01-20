<?php

namespace App\Http\Requests\Admin\Level;

use Illuminate\Foundation\Http\FormRequest;

class UpdateLevelRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'name'                   => ['sometimes', 'required', 'string', 'max:255'],
            'description'            => ['sometimes', 'nullable', 'string'],
            'background_image'       => ['sometimes', 'nullable', 'string', 'max:2048'],
            'order_index'            => ['sometimes', 'integer', 'min:1'],
            'is_active'              => ['sometimes', 'boolean'],
            'is_unlocked_by_default' => ['sometimes', 'boolean'],
        ];
    }
}
