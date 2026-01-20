<?php

namespace App\Http\Controllers\Admin\V01;

use App\Http\Requests\Admin\StageExercise\AttachStageExerciseRequest;
use App\Http\Requests\Admin\StageExercise\UpdateStageExerciseRequest;
use App\Models\Exercise;
use App\Models\Stage;
use App\Models\StageExercise;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class StageExerciseController extends Controller
{
    public function index(Request $request, int $stageId)
    {
        $stage = Stage::find($stageId);
        if (!$stage) return $this->returnError('Stage not found', 404);

        $includeInactive = $request->boolean('include_inactive', true);

        $q = StageExercise::with('exercise')
            ->where('stage_id', $stageId)
            ->orderBy('order_index');

        if (!$includeInactive) {
            $q->where('is_active', true);
        }

        $rows = $q->get()->map(function (StageExercise $se) {
            return [
                'id'          => $se->id,
                'stage_id'    => $se->stage_id,
                'exercise_id' => $se->exercise_id,
                'order_index' => $se->order_index,
                'repeat_count' => $se->repeat_count,
                'is_active'   => (bool) $se->is_active,
                'exercise'    => $se->exercise,
            ];
        });

        $this->setResult('stage', $stage);
        $this->setResult('stage_exercises', $rows);
        return $this->returnResponse();
    }

    public function show(int $id)
    {
        $row = StageExercise::with(['exercise', 'stage.level.world'])->find($id);

        if (!$row) {
            return $this->returnError('Stage exercise not found', 404);
        }

        $this->setResult('stage_exercise', [
            'id'           => $row->id,
            'stage_id'     => $row->stage_id,
            'exercise_id'  => $row->exercise_id,
            'order_index'  => $row->order_index,
            'repeat_count' => $row->repeat_count,
            'is_active'    => (bool) $row->is_active,
            'exercise'     => $row->exercise,
            'stage'        => $row->stage,
        ]);

        return $this->returnResponse();
    }

    public function store(AttachStageExerciseRequest $request, int $stageId)
    {
        $stage = Stage::find($stageId);
        if (!$stage) return $this->returnError('Stage not found', 404);

        $data = $request->validated();

        $exercise = Exercise::find($data['exercise_id']);
        if (!$exercise) return $this->returnError('Exercise not found', 404);

        $row = DB::transaction(function () use ($stageId, $data) {
            $existing = StageExercise::where('stage_id', $stageId)
                ->where('exercise_id', $data['exercise_id'])
                ->first();


            if ($existing) {
                $existing->is_active = true;

                if (isset($data['repeat_count'])) {
                    $existing->repeat_count = (int) $data['repeat_count'];
                }

                if (isset($data['order_index'])) {
                    $existing->order_index = (int) $data['order_index'];
                } else {

                    $max = (int) (StageExercise::where('stage_id', $stageId)->max('order_index') ?? 0);
                    $existing->order_index = max($existing->order_index ?? 0, $max + 1);
                }

                $existing->save();
                return $existing;
            }

            $order = $data['order_index'] ?? ((int) (StageExercise::where('stage_id', $stageId)->max('order_index') ?? 0) + 1);

            return StageExercise::create([
                'stage_id'     => $stageId,
                'exercise_id'  => (int) $data['exercise_id'],
                'order_index'  => (int) $order,
                'repeat_count' => (int) ($data['repeat_count'] ?? 3),
                'is_active'    => (bool) ($data['is_active'] ?? true),
            ]);
        });

        $this->setResult('stage_exercise', $row->load('exercise'));
        return $this->returnResponse();
    }

    public function update(UpdateStageExerciseRequest $request, int $id)
    {
        $row = StageExercise::find($id);
        if (!$row) return $this->returnError('Stage exercise not found', 404);

        $data = $request->validated();

        $row->fill($data);
        $row->save();

        $this->setResult('stage_exercise', $row->fresh()->load('exercise'));
        return $this->returnResponse();
    }

    public function toggle(int $id)
    {
        $row = StageExercise::find($id);
        if (!$row) return $this->returnError('Stage exercise not found', 404);

        $row->is_active = !$row->is_active;
        $row->save();

        $this->setResult('stage_exercise', $row->fresh()->load('exercise'));
        return $this->returnResponse();
    }

    public function reorder(Request $request, int $id)
    {
        $row = StageExercise::with('exercise')->find($id);
        if (!$row) return $this->returnError('Stage exercise not found', 404);

        $data = $request->validate([
            'order_index' => ['required', 'integer', 'min:1'],
        ]);

        $to = (int) $data['order_index'];

        DB::transaction(function () use ($row, $to) {
            $stageId = (int) $row->stage_id;


            $total = (int) StageExercise::where('stage_id', $stageId)->count();
            $to = max(1, min($to, $total));

            $from = (int) $row->order_index;
            if ($to === $from) return;


            StageExercise::where('id', $row->id)->update(['order_index' => 0]);

            if ($to > $from) {
                StageExercise::where('stage_id', $stageId)
                    ->whereBetween('order_index', [$from + 1, $to])
                    ->decrement('order_index', 1);
            } else {
                StageExercise::where('stage_id', $stageId)
                    ->whereBetween('order_index', [$to, $from - 1])
                    ->increment('order_index', 1);
            }

            StageExercise::where('id', $row->id)->update(['order_index' => $to]);
        });

        $rows = StageExercise::with('exercise')
            ->where('stage_id', $row->stage_id)
            ->orderBy('order_index')
            ->get()
            ->map(fn(StageExercise $se) => $this->mapRow($se));

        $this->setResult('stage_exercises', $rows);
        return $this->returnResponse();
    }

    public function destroy(int $id)
    {
        $row = StageExercise::find($id);
        if (!$row) return $this->returnError('Stage exercise not found', 404);

        $row->is_active = false;
        $row->save();

        $this->setResult('stage_exercise', $row->fresh()->load('exercise'));
        return $this->returnResponse();
    }

    private function mapRow(StageExercise $se): array
    {
        return [
            'id'           => $se->id,
            'stage_id'     => $se->stage_id,
            'exercise_id'  => $se->exercise_id,
            'order_index'  => $se->order_index,
            'repeat_count' => $se->repeat_count,
            'is_active'    => (bool) $se->is_active,
            'exercise'     => $se->exercise,
        ];
    }
}
