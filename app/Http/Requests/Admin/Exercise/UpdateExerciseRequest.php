<?php

namespace App\Http\Requests\Admin\Exercise;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateExerciseRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'prompt'         => ['sometimes', 'nullable', 'string', 'max:255'],
            'character'      => ['sometimes', 'nullable', 'string', 'max:50'],
            'question'       => ['sometimes', 'nullable', 'string', 'max:255'],

            'options'        => ['sometimes', 'nullable', 'array'],
            'options.*'      => ['nullable'],

            'correct_answer' => ['sometimes', 'nullable', 'string', 'max:255'],
            'instruction'    => ['sometimes', 'nullable', 'string'],
            'example'        => ['sometimes', 'nullable', 'string', 'max:255'],
            'hint'           => ['sometimes', 'nullable', 'string'],

            'character_type' => [
                'sometimes',
                'required',
                Rule::in(['digits', 'consonants', 'independent_vowels', 'dependent_vowels']),
            ],
        ];
    }
}
