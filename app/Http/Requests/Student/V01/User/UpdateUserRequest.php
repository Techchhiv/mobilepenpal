<?php

namespace App\Http\Requests\Student\V01\User;

use Illuminate\Foundation\Http\FormRequest;

class UpdateUserRequest extends FormRequest
{
    public function authorize()
    {
        return true;
    }

    public function rules(): array
    {
        $rawStudentId = $this->route('student') ?? $this->route('id') ?? auth()->id();
        $studentId = is_object($rawStudentId) ? $rawStudentId->id : $rawStudentId;

        return [
            'first_name' => 'sometimes|string|max:100',
            'last_name' => 'sometimes|nullable|string|max:100',
            'nickname' => 'sometimes|nullable|string|max:100',
            'age' => 'sometimes|nullable|integer|min:1|max:100',
            'gender' => 'sometimes|in:male,female,other',
            'date_of_birth' => 'sometimes|date',
            'avatar' => 'sometimes|nullable|string',

            'parent_first_name' => 'sometimes|nullable|string|max:100',
            'parent_last_name' => 'sometimes|nullable|string|max:100',
            'address' => 'sometimes|nullable|string',
            'enrollment_year' => 'sometimes|nullable|string',

            'email' => 'sometimes|required|email|max:255|unique:students,email,' . $studentId,
            'phone' => 'sometimes|nullable|string|unique:students,phone,' . $studentId,
            'password' => 'sometimes|nullable|string|min:6',
        ];
    }
}
