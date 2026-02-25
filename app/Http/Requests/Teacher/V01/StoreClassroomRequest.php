<?php

namespace App\Http\Requests\Teacher\V01;

use Illuminate\Foundation\Http\FormRequest;

class StoreClassroomRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            // 'branch_id'   => ['required', 'exists:branches,id'],
            'teacher_id' => ['nullable', 'exists:teachers,id'],
            'name'        => ['required', 'string', 'max:255'],
            // 'grade_level' => ['nullable', 'string', 'max:50'],
            // 'subject'     => ['nullable', 'string', 'max:100'],
            'start_date'  => ['nullable', 'date'],
            'end_date'    => ['nullable', 'date', 'after_or_equal:start_date'],
        ];
    }
}
