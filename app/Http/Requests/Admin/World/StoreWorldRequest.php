<?php

namespace App\Http\Requests\Admin\World;

use Illuminate\Foundation\Http\FormRequest;

class StoreWorldRequest extends FormRequest
{
    public function rules()
    {
        return [
            'audience' => ['required', 'in:public,schools,assigned'],
            'school_ids' => ['sometimes', 'array'],
            'name' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'icon_url' => ['nullable', 'string', 'max:2048'],
            'map_image_url' => ['nullable', 'string', 'max:2048'],
            'theme_color' => ['nullable', 'string', 'max:32'],
            'is_active' => ['nullable', 'boolean'],
            'is_unlocked_by_default' => ['nullable', 'boolean'],
            'order_index' => ['nullable', 'integer', 'min:1'],
        ];
    }
}
