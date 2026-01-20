<?php

namespace App\Http\Requests\Admin\Level;

use Illuminate\Foundation\Http\FormRequest;

class ReorderLevelsRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'level_ids'   => ['required', 'array', 'min:1'],
            'level_ids.*' => ['integer', 'distinct'],
        ];
    }
}
