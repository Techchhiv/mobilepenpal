<?php

namespace App\Http\Controllers\Student\V01;

use App\Models\QuestionTemplate;

class QuestionTemplateController extends Controller
{
    public function index()
    {
        $templates = QuestionTemplate::where('is_active', true)
            ->orderBy('id')
            ->get();

        return $this->returnSuccess('OK', [
            'question_templates' => $templates,
        ]);
    }
}
