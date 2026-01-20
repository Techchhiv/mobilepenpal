<?php

namespace App\Http\Requests\Admin\StageExercise;

use Illuminate\Foundation\Http\FormRequest;

class UpdateStageExerciseRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'repeat_count' => ['sometimes', 'integer', 'min:1', 'max:20'],
            'order_index'  => ['sometimes', 'integer', 'min:1'],
            'is_active'    => ['sometimes', 'boolean'],
        ];
    }
}
