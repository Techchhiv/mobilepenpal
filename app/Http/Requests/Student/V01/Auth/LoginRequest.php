<?php

namespace App\Http\Requests\Student\V01\Auth;

use Illuminate\Foundation\Http\FormRequest;

class LoginRequest extends FormRequest
{
    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, mixed>
     */
    public function rules()
    {
        return [
            'login' => 'nullable|string|required_without_all:email,phone',
            'phone' => 'nullable|string|required_without_all:login,email',
            'email' => 'nullable|string|required_without_all:login,phone',
            'password' => 'required|string|min:6',
            'confirm' => 'nullable|boolean',
            // 'school_key' => 'required|string',
        ];
    }
}
