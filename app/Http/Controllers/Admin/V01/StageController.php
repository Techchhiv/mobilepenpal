<?php

namespace App\Http\Controllers\Admin\V01;

use App\Http\Requests\Admin\Stage\StoreStageGlobalRequest;
use App\Http\Requests\Admin\Stage\StoreStageRequest;
use App\Http\Requests\Admin\Stage\UpdateStageRequest;
use App\Models\Level;
use App\Models\Stage;
use App\Models\StageExercise;
use App\Models\StudentLevelProgress;
use App\Models\StudentStageProgress;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class StageController extends Controller
{
    public function index(Request $request, int $levelId)
    {
        $includeInactive = $request->boolean('include_inactive', true);

        $level = Level::with('world')->find($levelId);
        if (!$level) return $this->returnError('Level not found', 404);

        $q = Stage::where('level_id', $levelId)->orderBy('order_index');

        if (!$includeInactive) {
            $q->where('is_active', true);
        }

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

    public function indexGlobal(Request $request)
    {
        $includeInactive = $request->boolean('include_inactive', true);

        $worldId = $request->input('world_id');
        $levelId = $request->input('level_id');
        $qSearch = trim((string) $request->input('q', ''));

        $perPage = (int) $request->input('per_page', 0);
        $perPage = $perPage > 0 ? min(max($perPage, 1), 200) : 0;

        if ($request->filled('level_id')) {
            $level = Level::with('world')->find((int) $levelId);
            if (!$level) return $this->returnError('Level not found', 404);
            $this->setResult('level', $level);
        }

        $q = Stage::query()
            ->select('stages.*')
            ->join('levels', 'levels.id', '=', 'stages.level_id');

        if ($request->filled('level_id')) {
            $q->where('stages.level_id', (int) $levelId);
        }

        if ($request->filled('world_id')) {
            $q->where('levels.world_id', (int) $worldId);
        }

        if (!$includeInactive) {
            $q->where('stages.is_active', true);
        }

        if ($qSearch !== '') {
            $q->where(function ($qq) use ($qSearch) {
                $qq->where('stages.name', 'like', "%{$qSearch}%")
                    ->orWhere('stages.name_en', 'like', "%{$qSearch}%")
                    ->orWhere('stages.description', 'like', "%{$qSearch}%")
                    ->orWhere('stages.description_en', 'like', "%{$qSearch}%")
                    ->orWhere('stages.instruction', 'like', "%{$qSearch}%")
                    ->orWhere('stages.instruction_en', 'like', "%{$qSearch}%");
            });
        }

        $q->selectSub(function ($sq) {
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

        $q->orderBy('levels.world_id')
            ->orderBy('levels.order_index')
            ->orderBy('stages.order_index');

        $q->with(['level.world']);

        $stages = $perPage > 0
            ? $q->paginate($perPage)->appends($request->query())
            : $q->get();

        $this->setResult('stages', $stages);
        return $this->returnResponse();
    }


    public function show(int $id)
    {
        $stage = Stage::with([
            'level.world',
            'stageExercises' => fn($q) => $q->orderBy('order_index'),
            'stageExercises.exercise',
        ])->find($id);

        if (!$stage) return $this->returnError('Stage not found', 404);

        $stage->exercises_count = $stage->stageExercises->count();
        $stage->active_exercises_count = $stage->stageExercises->where('is_active', true)->count();

        $this->setResult('stage', $stage);
        return $this->returnResponse();
    }



    public function store(StoreStageRequest $request, int $levelId)
    {
        $level = Level::with('world')->find($levelId);
        if (!$level) return $this->returnError('Level not found', 404);

        $data = $request->validated();

        $stage = DB::transaction(function () use ($data, $levelId) {
            if (!isset($data['order_index'])) {
                $max = (int) (Stage::where('level_id', $levelId)->max('order_index') ?? 0);
                $data['order_index'] = $max + 1;
            }

            $data['is_active'] = $data['is_active'] ?? true;
            $data['level_id']  = $levelId;

            return Stage::create($data);
        });

        $this->setResult('stage', $stage);
        return $this->returnResponse();
    }

    public function storeGlobal(StoreStageGlobalRequest $request)
    {
        $data = $request->validated();

        $levelId = (int) $data['level_id'];

        $level = Level::with('world')->find($levelId);
        if (!$level) return $this->returnError('Level not found', 404);

        $stage = DB::transaction(function () use ($data, $levelId) {
            if (!isset($data['order_index'])) {
                $max = (int) (Stage::where('level_id', $levelId)->max('order_index') ?? 0);
                $data['order_index'] = $max + 1;
            }

            $data['is_active'] = $data['is_active'] ?? true;
            $data['max_stars'] = $data['max_stars'] ?? 3;

            $data['level_id'] = $levelId;

            return Stage::create($data);
        });

        $this->setResult('stage', $stage->load(['level.world']));
        return $this->returnResponse();
    }

    public function update(UpdateStageRequest $request, int $id)
    {
        $stage = Stage::find($id);
        if (!$stage) return $this->returnError('Stage not found', 404);

        $data = $request->validated();

        $stage->fill($data);
        $stage->save();

        $this->setResult('stage', $stage->fresh());
        return $this->returnResponse();
    }

    public function toggle(int $id)
    {
        $stage = Stage::with(['level.world'])->find($id);
        if (!$stage) return $this->returnError('Stage not found', 404);

        $wasActive = (bool) $stage->is_active;
        $stage->is_active = !$stage->is_active;
        $stage->save();

        if ($wasActive && !$stage->is_active) {
            $this->reconcileStudentsAfterStageDisabled($stage);
        }

        $this->setResult('stage', $stage->fresh());
        return $this->returnResponse();
    }

    public function reorder(Request $request, int $id)
    {
        $stage = Stage::find($id);
        if (!$stage) return $this->returnError('Stage not found', 404);

        $data = $request->validate([
            'order_index' => ['required', 'integer', 'min:1'],
        ]);

        $to = (int) $data['order_index'];

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

        $this->setResult(
            'stages',
            Stage::where('level_id', $stage->level_id)->orderBy('order_index')->get()
        );

        return $this->returnResponse();
    }

    private function reconcileStudentsAfterStageDisabled(Stage $disabledStage): void
    {
        $level = Level::find($disabledStage->level_id);
        if (!$level) return;

        $worldId = (int) $level->world_id;

        $nextStage = Stage::where('level_id', $disabledStage->level_id)
            ->where('is_active', true)
            ->where('order_index', '>', $disabledStage->order_index)
            ->orderBy('order_index')
            ->first();

        $nextLevel = null;
        $firstStageNextLevel = null;

        if (!$nextStage) {
            $nextLevel = Level::where('world_id', $worldId)
                ->where('is_active', true)
                ->where('order_index', '>', $level->order_index)
                ->orderBy('order_index')
                ->first();

            while ($nextLevel) {
                $firstStageNextLevel = Stage::where('level_id', $nextLevel->id)
                    ->where('is_active', true)
                    ->orderBy('order_index')
                    ->first();

                if ($firstStageNextLevel) break;

                $nextLevel = Level::where('world_id', $worldId)
                    ->where('is_active', true)
                    ->where('order_index', '>', $nextLevel->order_index)
                    ->orderBy('order_index')
                    ->first();
            }
        }

        $studentIds = StudentStageProgress::where('stage_id', $disabledStage->id)
            ->whereIn('status', ['unlocked', 'locked'])
            ->pluck('student_id')
            ->unique();

        if ($studentIds->isEmpty()) return;

        DB::transaction(function () use ($studentIds, $nextStage, $nextLevel, $firstStageNextLevel) {
            foreach ($studentIds as $studentId) {
                if ($nextStage) {
                    $progress = StudentStageProgress::firstOrNew([
                        'student_id' => $studentId,
                        'stage_id'   => $nextStage->id,
                    ]);

                    if (!$progress->exists) {
                        $progress->status = 'unlocked';
                        $progress->stars_earned = 0;
                        $progress->save();
                    } elseif ($progress->status === 'locked') {
                        $progress->status = 'unlocked';
                        $progress->save();
                    }
                    continue;
                }

                if ($nextLevel && $firstStageNextLevel) {
                    StudentLevelProgress::updateOrCreate(
                        ['student_id' => $studentId, 'level_id' => $nextLevel->id],
                        ['is_unlocked' => true, 'is_completed' => false]
                    );

                    $p = StudentStageProgress::firstOrNew([
                        'student_id' => $studentId,
                        'stage_id'   => $firstStageNextLevel->id,
                    ]);

                    if (!$p->exists) {
                        $p->status = 'unlocked';
                        $p->stars_earned = 0;
                        $p->save();
                    } elseif ($p->status === 'locked') {
                        $p->status = 'unlocked';
                        $p->save();
                    }
                }
            }
        });
    }
}
