<?php

namespace App\Http\Requests\Admin\Student;

use Illuminate\Foundation\Http\FormRequest;

class StoreStudentRequest extends FormRequest
{

    public function rules(): array
    {
        $maxYear = (int) now()->year + 1;

        return [
            'school_id'  => ['nullable', 'integer', 'exists:schools,id'],
            'first_name' => ['required', 'string', 'max:100'],
            'last_name'  => ['nullable', 'string', 'max:100'],
            'nickname'   => ['nullable', 'string', 'max:100'],
            'age'        => ['nullable', 'integer', 'min:1', 'max:100'],
            'gender'     => ['nullable', 'in:male,female,other'],
            'date_of_birth' => ['nullable', 'date'],
            'avatar'     => ['nullable', 'string'],

            'parent_first_name' => ['required', 'string', 'max:100'],
            'parent_last_name'  => ['required', 'string', 'max:100'],
            'parent_pin'        => ['nullable', 'string', 'max:20'],

            'email' => ['nullable', 'email', 'unique:students,email'],
            'phone' => ['required', 'string', 'unique:students,phone'],
            'password' => ['required', 'string', 'min:6'],

            'address' => ['nullable', 'string', 'max:255'],
            'enrollment_year' => ['nullable', 'integer', 'min:1900', 'max:' . $maxYear],
            'is_active' => ['sometimes', 'boolean'],
        ];
    }
}
