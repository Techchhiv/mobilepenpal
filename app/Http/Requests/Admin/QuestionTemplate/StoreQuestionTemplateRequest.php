<?php
namespace App\Http\Requests\Admin\QuestionTemplate;

use Illuminate\Foundation\Http\FormRequest;

class StoreQuestionTemplateRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'question_en' => ['required', 'string'],
            'question_kh' => ['required', 'string'],
            'operation'   => ['required', 'in:add,sub,mul,div'],
            'difficulty'  => ['required', 'in:easy,medium,hard'],
            'is_active'   => ['nullable', 'boolean'],
        ];
    }
}
