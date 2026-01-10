<?php

namespace App\Http\Requests\Student\V01\User;

use Illuminate\Foundation\Http\FormRequest;

class UpdateUserRequest extends FormRequest
{
    public function authorize()
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, mixed>
     */
    public function rules()
    {
        return [
            'first_name' => 'sometimes|string|max:100',
            'last_name' => 'sometimes|nullable|string|max:100',
            'nickname' => 'sometimes|nullable|string|max:100',
            'age' => 'sometimes|nullable|integer|min:1|max:100',
            'gender' => 'sometimes|in:male,female,other',
            'date_of_birth' => 'sometimes|date',
            'avatar' => [
                'sometimes',
                'nullable',
                'string',
                'regex:/^data:image\/(png|jpe?g);base64,/',
            ],

            'parent_first_name' => 'sometimes|nullable|string|max:100',
            'parent_last_name' => 'sometimes|nullable|string|max:100',
            'address' => 'sometimes|nullable|string',
            'enrollment_year' => 'sometimes|nullable|string',
        ];
    }
}
