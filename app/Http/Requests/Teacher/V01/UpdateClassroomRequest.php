<?php

namespace App\Http\Requests\Teacher\V01;

use Illuminate\Foundation\Http\FormRequest;

class UpdateClassroomRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'name'        => ['sometimes', 'string', 'max:255'],
            // 'grade_level' => ['sometimes', 'nullable', 'string', 'max:50'],
            // 'subject'     => ['sometimes', 'nullable', 'string', 'max:100'],
            'start_date'  => ['sometimes', 'nullable', 'date'],
            'end_date'    => ['sometimes', 'nullable', 'date'],
            'is_active'   => ['sometimes', 'boolean'],
        ];
    }
}
