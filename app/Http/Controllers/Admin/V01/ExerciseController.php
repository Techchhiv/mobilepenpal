<?php

namespace App\Http\Controllers\Admin\V01;

use App\Http\Requests\Admin\Exercise\StoreExerciseRequest;
use App\Http\Requests\Admin\Exercise\UpdateExerciseRequest;
use App\Models\Exercise;
use Illuminate\Http\Request;

class ExerciseController extends Controller
{
    public function index(Request $request)
    {
        $perPage = (int) $request->query('per_page', 50);
        $perPage = max(1, min($perPage, 200));

        $q = Exercise::query()
            ->orderBy('id')
            ->withCount([
                'stageExercises as used_count',
            ]);

        if ($request->filled('stage_id')) {
            $stageId = (int) $request->query('stage_id');

            $q->whereIn('id', function ($sub) use ($stageId) {
                $sub->from('stage_exercises')
                    ->select('exercise_id')
                    ->where('stage_id', $stageId);
            });
        }

        if ($request->filled('character_type')) {
            $q->where('character_type', $request->query('character_type'));
        }

        if ($request->filled('character')) {
            $q->where('character', $request->query('character'));
        }

        if ($request->filled('q')) {
            $keyword = $request->query('q');
            $q->where(function ($qq) use ($keyword) {
                $qq->where('prompt', 'like', "%{$keyword}%")
                    ->orWhere('question', 'like', "%{$keyword}%")
                    ->orWhere('instruction', 'like', "%{$keyword}%")
                    ->orWhere('hint', 'like', "%{$keyword}%")
                    ->orWhere('example', 'like', "%{$keyword}%")
                    ->orWhere('character', 'like', "%{$keyword}%");
            });
        }

        $exercises = $q->paginate($perPage);

        $this->setResult('exercises', $exercises);
        return $this->returnResponse();
    }

    public function show(int $id)
    {
        $exercise = Exercise::with(['stageExercises.stage.level.world'])->find($id);
        if (!$exercise) return $this->returnError('Exercise not found', 404);

        $this->setResult('exercise', $exercise);
        return $this->returnResponse();
    }

    public function store(StoreExerciseRequest $request)
    {
        $data = $request->validated();

        $exercise = Exercise::create($data);

        $this->setResult('exercise', $exercise);
        return $this->returnResponse();
    }

    public function update(UpdateExerciseRequest $request, int $id)
    {
        $exercise = Exercise::find($id);
        if (!$exercise) return $this->returnError('Exercise not found', 404);

        $data = $request->validated();

        $exercise->fill($data);
        $exercise->save();

        $this->setResult('exercise', $exercise->fresh());
        return $this->returnResponse();
    }
}
