<?php

namespace App\Http\Requests\Teacher\V01;

use Illuminate\Foundation\Http\FormRequest;

class RegisterRequest extends FormRequest
{
    public function rules()
    {
        return [
            'branch_id' => ['required', 'integer', 'exists:branches,id'],

            'name'     => ['required', 'string', 'max:255'],
            'email'    => ['required', 'email', 'unique:teachers,email'],
            'password' => ['required', 'string', 'min:8'],

            'phone'    => ['nullable', 'string', 'max:30'],
            'subject'  => ['nullable', 'string', 'max:100'],
        ];
    }
}
