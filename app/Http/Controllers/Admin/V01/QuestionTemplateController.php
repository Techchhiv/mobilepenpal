<?php

namespace App\Http\Controllers\Admin\V01;

use App\Http\Requests\Admin\QuestionTemplate\StoreQuestionTemplateRequest;
use App\Http\Requests\Admin\QuestionTemplate\UpdateQuestionTemplateRequest;
use App\Models\QuestionTemplate;
use Illuminate\Http\Request;

class QuestionTemplateController extends Controller
{
    public function index(Request $request)
    {
        $perPage = (int) $request->query('per_page', 50);
        $perPage = max(1, min($perPage, 200));

        $q = QuestionTemplate::query()->orderBy('id');

        if ($request->filled('operation')) {
            $q->where('operation', $request->query('operation'));
        }

        if ($request->filled('difficulty')) {
            $q->where('difficulty', $request->query('difficulty'));
        }

        if ($request->filled('is_active')) {
            $q->where('is_active', filter_var($request->query('is_active'), FILTER_VALIDATE_BOOLEAN));
        }

        if ($request->filled('q')) {
            $keyword = $request->query('q');
            $q->where(function ($qq) use ($keyword) {
                $qq->where('question_en', 'like', "%{$keyword}%")
                    ->orWhere('question_kh', 'like', "%{$keyword}%");
            });
        }

        $templates = $q->paginate($perPage);

        $this->setResult('question_templates', $templates);
        return $this->returnResponse();
    }

    public function show(int $id)
    {
        $template = QuestionTemplate::find($id);
        if (!$template) return $this->returnError('Question template not found', 404);

        $this->setResult('question_template', $template);
        return $this->returnResponse();
    }

    public function store(StoreQuestionTemplateRequest $request)
    {
        $data = $request->validated();
        if (!isset($data['is_active'])) {
            $data['is_active'] = true;
        }

        $template = QuestionTemplate::create($data);

        $this->setResult('question_template', $template);
        return $this->returnResponse();
    }

    public function update(UpdateQuestionTemplateRequest $request, int $id)
    {
        $template = QuestionTemplate::find($id);
        if (!$template) return $this->returnError('Question template not found', 404);

        $data = $request->validated();

        $template->fill($data);
        $template->save();

        $this->setResult('question_template', $template->fresh());
        return $this->returnResponse();
    }

    public function destroy(int $id)
    {
        $template = QuestionTemplate::find($id);
        if (!$template) return $this->returnError('Question template not found', 404);

        $template->delete();

        return $this->returnSuccess('Question template deleted successfully');
    }
}
