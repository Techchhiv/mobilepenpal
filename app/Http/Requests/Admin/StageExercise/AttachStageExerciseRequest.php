<?php

namespace App\Http\Requests\Admin\StageExercise;

use Illuminate\Foundation\Http\FormRequest;

class AttachStageExerciseRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'exercise_id'  => ['required', 'integer'],
            'repeat_count' => ['nullable', 'integer', 'min:1', 'max:20'],
            'order_index'  => ['nullable', 'integer', 'min:1'],
            'is_active'    => ['nullable', 'boolean'],
        ];
    }
}
