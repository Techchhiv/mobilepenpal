<?php
namespace App\Http\Requests\Admin\QuestionTemplate;

use Illuminate\Foundation\Http\FormRequest;

class UpdateQuestionTemplateRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'question_en' => ['sometimes', 'required', 'string'],
            'question_kh' => ['sometimes', 'required', 'string'],
            'operation'   => ['sometimes', 'required', 'in:add,sub,mul,div'],
            'difficulty'  => ['sometimes', 'required', 'in:easy,medium,hard'],
            'is_active'   => ['sometimes', 'boolean'],
        ];
    }
}
