<?php

namespace App\Http\Requests\Student\V01\Auth;

use Illuminate\Foundation\Http\FormRequest;

class RegisterRequest extends FormRequest
{
    public function rules()
    {
        $maxYear = (int) now()->year + 1;

        return [
            'school_id'  => 'nullable|exists:schools,id',
            'school_key' => 'nullable|string|max:255',

            'first_name' => 'required|string|max:100',
            'last_name'  => 'nullable|string|max:100',
            'nickname'   => 'nullable|string|max:100',
            'age'        => 'nullable|integer|min:1|max:100',
            'gender'     => 'nullable|in:male,female',
            'date_of_birth' => 'nullable|date',
            'avatar'     => 'nullable|string',

            'parent_pin' => 'nullable|string|max:20',

            'parent_first_name' => 'required|string|max:100',
            'parent_last_name'  => 'required|string|max:100',

            // 'email' => 'required|string|email|max:255|unique:students,email',
            'email' => 'nullable|email|unique:students,email',
            'phone' => 'required|string|unique:students,phone',
            'password' => 'required|string|min:6',

            'address' => 'nullable|string|max:255',
            'enrollment_year' => 'nullable|integer|min:1900|max:' . $maxYear,
        ];
    }
}
