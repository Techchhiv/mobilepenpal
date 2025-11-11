<?php

namespace App\Http\Requests\Student\V01\Auth;

use Illuminate\Foundation\Http\FormRequest;

class RegisterRequest extends FormRequest
{
    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, mixed>
     */
    public function rules()
    {
        return [
            'school_id' => 'required|exists:schools,id',
            'school_key' => 'required|string|exists:schools,school_key',
            'first_name' => 'required|string|max:100',
            'last_name' => 'required|string|max:100',
            'age'=> 'required|int',
            'date_of_birth' => 'required|date',
            'gender' => 'required|in:male,female',

            'parent_first_name' => 'nullable|string|max:100',
            'parent_last_name' => 'nullable|string|max:100',
            'email' => 'nullable|email|unique:students,email',
            'phone' => 'required|string|unique:students,phone',
            'password' => 'required|string|min:6',

            'address' => 'nullable|string',
            'enrollment_year' => 'nullable'
        ];
    }
}
