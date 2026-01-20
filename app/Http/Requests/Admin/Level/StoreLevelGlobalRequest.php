<?php

namespace App\Http\Requests\Admin\Level;

use Illuminate\Foundation\Http\FormRequest;

class StoreLevelGlobalRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'world_id'               => ['required', 'integer', 'exists:worlds,id'],

            'name'                   => ['required', 'string', 'max:255'],
            'description'            => ['nullable', 'string'],
            'background_image'       => ['nullable', 'string', 'max:2048'],
            'order_index'            => ['nullable', 'integer', 'min:1'],
            'is_active'              => ['nullable', 'boolean'],
            'is_unlocked_by_default' => ['nullable', 'boolean'],
        ];
    }
}
