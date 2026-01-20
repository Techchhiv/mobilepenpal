<?php

namespace App\Http\Requests\Admin\Exercise;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreExerciseRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'prompt'         => ['nullable', 'string', 'max:255'],
            'character'      => ['nullable', 'string', 'max:50'],
            'question'       => ['nullable', 'string', 'max:255'],

            // allow either array or null; controller will json_encode it
            'options'        => ['nullable', 'array'],
            'options.*'      => ['nullable'],

            'correct_answer' => ['nullable', 'string', 'max:255'],
            'instruction'    => ['nullable', 'string'],
            'example'        => ['nullable', 'string', 'max:255'],
            'hint'           => ['nullable', 'string'],

            'character_type' => [
                'required',
                Rule::in(['digits', 'consonants', 'independent_vowels', 'dependent_vowels']),
            ],
        ];
    }
}
