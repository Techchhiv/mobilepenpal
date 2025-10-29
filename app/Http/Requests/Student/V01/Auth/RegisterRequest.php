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
            'first_name' => 'required|string|max:100',
            'last_name' => 'required|string|max:100',
            'date_of_birth' => 'required|date',
            'gender' => 'required|in:male,female,other',
            'email' => 'nullable|email|unique:students,email',
            'phone' => 'required|string|unique:students,phone',
            'password' => 'required|string|min:6',
            'school_key' => 'required|string',

            'parent_first_name' => 'nullable|string|max:100',
            'parent_last_name' => 'nullable|string|max:100',
            'parent_email' => 'nullable|email|unique:students,parent_email',
            'parent_phone' => 'nullable|string|unique:students,parent_phone',

            'address' => 'nullable|string',
        ];
    }
}
