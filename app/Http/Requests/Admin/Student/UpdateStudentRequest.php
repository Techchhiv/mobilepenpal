<?php

namespace App\Http\Requests\Admin\Student;

use Illuminate\Foundation\Http\FormRequest;

class UpdateStudentRequest extends FormRequest
{
    public function rules(): array
    {
        $maxYear = (int) now()->year + 1;
        $studentId = (int) $this->route('id');

        return [
            'school_id'  => ['nullable', 'integer', 'exists:schools,id'],
            'first_name' => ['sometimes', 'required', 'string', 'max:100'],
            'last_name'  => ['sometimes', 'nullable', 'string', 'max:100'],
            'nickname'   => ['sometimes', 'nullable', 'string', 'max:100'],
            'age'        => ['sometimes', 'nullable', 'integer', 'min:1', 'max:100'],
            'gender'     => ['sometimes', 'nullable', 'in:male,female,other'],
            'date_of_birth' => ['sometimes', 'nullable', 'date'],
            'avatar'     => ['sometimes', 'nullable', 'string'],

            'parent_first_name' => ['sometimes', 'required', 'string', 'max:100'],
            'parent_last_name'  => ['sometimes', 'required', 'string', 'max:100'],
            'parent_pin'        => ['sometimes', 'nullable', 'string', 'max:20'],

            'email' => ['sometimes', 'required', 'email', 'max:255', 'unique:students,email,' . $studentId],
            'phone' => ['sometimes', 'nullable', 'string', 'unique:students,phone,' . $studentId],
            'password' => ['sometimes', 'nullable', 'string', 'min:6'],

            'address' => ['sometimes', 'nullable', 'string', 'max:255'],
            'enrollment_year' => ['sometimes', 'nullable', 'integer', 'min:1900', 'max:' . $maxYear],
            'is_active' => ['sometimes', 'boolean'],
        ];
    }
}
