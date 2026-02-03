<?php

namespace App\Http\Controllers\School\V01;

use App\Http\Requests\School\Level\StoreLevelRequest;
use App\Http\Requests\School\Stage\StoreStageRequest;
use App\Http\Requests\School\Stage\UpdateStageRequest;
use App\Models\Level;
use App\Models\Stage;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class StageController extends Controller
{
    public function index(Request $request, int $levelId)
    {
        $schoolId = (int) (auth()->user()->school_id ?? 0);
        if ($schoolId <= 0) return $this->returnError('School account required', 403);

        $includeInactive = $request->boolean('include_inactive', true);

        $level = Level::where('id', $levelId)
            ->whereHas('world', fn($w) => $w->where('school_id', $schoolId))
            ->with('world')
            ->first();

        if (!$level) return $this->returnError('Level not found', 404);

        $q = Stage::where('level_id', $levelId)->orderBy('order_index');
        if (!$includeInactive) $q->where('is_active', true);

        $q->select('stages.*')
            ->selectSub(function ($sq) {
                $sq->from('stage_exercises')
                    ->whereColumn('stage_exercises.stage_id', 'stages.id')
                    ->selectRaw('COUNT(*)');
            }, 'exercises_count')
            ->selectSub(function ($sq) {
                $sq->from('stage_exercises')
                    ->whereColumn('stage_exercises.stage_id', 'stages.id')
                    ->where('stage_exercises.is_active', true)
                    ->selectRaw('COUNT(*)');
            }, 'active_exercises_count');

        $stages = $q->get();

        $this->setResult('level', $level);
        $this->setResult('stages', $stages);
        return $this->returnResponse();
    }

    public function show(int $id)
    {
        $schoolId = (int) (auth()->user()->school_id ?? 0);
        if ($schoolId <= 0) return $this->returnError('School account required', 403);

        $stage = Stage::query()
            ->where('id', $id)
            ->whereHas('level.world', fn($w) => $w->where('school_id', $schoolId))
            ->with([
                'level.world',
                'stageExercises' => fn($q) => $q->orderBy('order_index'),
                'stageExercises.exercise',
            ])
            ->first();

        if (!$stage) return $this->returnError('Stage not found', 404);

        $stage->exercises_count = $stage->stageExercises->count();
        $stage->active_exercises_count = $stage->stageExercises->where('is_active', true)->count();

        $this->setResult('stage', $stage);
        return $this->returnResponse();
    }

    public function store(StoreStageRequest $request, int $levelId)
    {
        $schoolId = (int) (auth()->user()->school_id ?? 0);
        if ($schoolId <= 0) return $this->returnError('School account required', 403);

        $level = Level::where('id', $levelId)
            ->whereHas('world', fn($w) => $w->where('school_id', $schoolId))
            ->first();

        if (!$level) return $this->returnError('Level not found', 404);

        $data = $request->validated();

        $stage = DB::transaction(function () use ($data, $levelId) {
            if (!isset($data['order_index'])) {
                $max = (int) (Stage::where('level_id', $levelId)->max('order_index') ?? 0);
                $data['order_index'] = $max + 1;
            }

            $data['level_id'] = $levelId;
            $data['is_active'] = $data['is_active'] ?? true;
            $data['is_unlocked_by_default'] = $data['is_unlocked_by_default'] ?? false;
            $data['max_stars'] = $data['max_stars'] ?? 3;

            return Stage::create($data);
        });

        $this->setResult('stage', $stage);
        return $this->returnResponse();
    }

    public function update(UpdateStageRequest $request, int $id)
    {
        $schoolId = (int) (auth()->user()->school_id ?? 0);
        if ($schoolId <= 0) return $this->returnError('School account required', 403);

        $stage = Stage::where('id', $id)
            ->whereHas('level.world', fn($w) => $w->where('school_id', $schoolId))
            ->first();

        if (!$stage) return $this->returnError('Stage not found', 404);

        $data = $request->validated();

        $stage->fill($data);
        $stage->save();

        $this->setResult('stage', $stage->fresh());
        return $this->returnResponse();
    }

    public function toggle(int $id)
    {
        $schoolId = (int) (auth()->user()->school_id ?? 0);
        if ($schoolId <= 0) return $this->returnError('School account required', 403);

        $stage = Stage::where('id', $id)
            ->whereHas('level.world', fn($w) => $w->where('school_id', $schoolId))
            ->first();

        if (!$stage) return $this->returnError('Stage not found', 404);

        $stage->is_active = !$stage->is_active;
        $stage->save();

        $this->setResult('stage', $stage->fresh());
        return $this->returnResponse();
    }

    public function reorder(Request $request, int $id)
    {
        $schoolId = (int) (auth()->user()->school_id ?? 0);
        if ($schoolId <= 0) return $this->returnError('School account required', 403);

        $data = $request->validate([
            'order_index' => ['required', 'integer', 'min:1'],
        ]);

        $to = (int) $data['order_index'];

        $stage = Stage::where('id', $id)
            ->whereHas('level.world', fn($w) => $w->where('school_id', $schoolId))
            ->first();

        if (!$stage) return $this->returnError('Stage not found', 404);

        DB::transaction(function () use ($stage, $to) {
            $levelId = (int) $stage->level_id;
            $total = (int) Stage::where('level_id', $levelId)->count();

            $to = max(1, min($to, $total));
            $from = (int) $stage->order_index;

            if ($to === $from) return;

            Stage::where('id', $stage->id)->update(['order_index' => 0]);

            if ($to > $from) {
                Stage::where('level_id', $levelId)
                    ->whereBetween('order_index', [$from + 1, $to])
                    ->decrement('order_index', 1);
            } else {
                Stage::where('level_id', $levelId)
                    ->whereBetween('order_index', [$to, $from - 1])
                    ->increment('order_index', 1);
            }

            Stage::where('id', $stage->id)->update(['order_index' => $to]);
        });

        $this->setResult('stages', Stage::where('level_id', $stage->level_id)->orderBy('order_index')->get());
        return $this->returnResponse();
    }
}
