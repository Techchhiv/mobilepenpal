<?php

namespace App\Http\Requests\Admin\World;

use Illuminate\Foundation\Http\FormRequest;

class UpdateWorldRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'name' => ['sometimes', 'required', 'string', 'max:255'],
            'description' => ['sometimes', 'nullable', 'string'],
            'icon_url' => ['sometimes', 'nullable', 'string', 'max:2048'],
            'map_image_url' => ['sometimes', 'nullable', 'string', 'max:2048'],
            'theme_color' => ['sometimes', 'nullable', 'string', 'max:32'],
            'is_active' => ['sometimes', 'boolean'],
            'is_unlocked_by_default' => ['sometimes', 'boolean'],
            'order_index' => ['sometimes', 'integer', 'min:1'],
        ];
    }
}
