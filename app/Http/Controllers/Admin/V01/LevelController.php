<?php

namespace App\Http\Controllers\Admin\V01;

use App\Http\Requests\Admin\Level\ReorderLevelsRequest;
use App\Http\Requests\Admin\Level\StoreLevelGlobalRequest;
use App\Http\Requests\Admin\Level\StoreLevelRequest;
use App\Http\Requests\Admin\Level\UpdateLevelRequest;
use App\Models\Level;
use App\Models\Stage;
use App\Models\World;
use App\Models\StudentLevelProgress;
use App\Models\StudentStageProgress;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class LevelController extends Controller
{
    public function index(Request $request, int $worldId)
    {
        $includeInactive = $request->boolean('include_inactive', true);
        $withStages = $request->boolean('with_stages', false);

        $world = World::find($worldId);
        if (!$world) return $this->returnError('World not found', 404);

        $levelsQuery = Level::where('world_id', $worldId)
            // ->where('is_active', true)
            ->orderBy('order_index');

        if (!$includeInactive) {
            $levelsQuery->where('is_active', true);
        }

        if ($withStages) {
            $levelsQuery->with(['stages' => function ($q) use ($includeInactive) {
                if (!$includeInactive) {
                    $q->where('is_active', true);
                }
                $q->orderBy('order_index');
            }]);
        } else {
            $levelsQuery->withCount([
                'stages as stages_count',
                'stages as active_stages_count' => fn($q) => $q->where('is_active', true),
            ]);
        }

        $levels = $levelsQuery->get();

        $this->setResult('world', $world);
        $this->setResult('levels', $levels);
        return $this->returnResponse();
    }

    public function indexGlobal(Request $request)
    {
        $includeInactive = $request->boolean('include_inactive', true);
        $withStages = $request->boolean('with_stages', false);

        $worldId = $request->input('world_id');
        $q = trim((string) $request->input('q', ''));

        $perPage = (int) $request->input('per_page', 0);
        $perPage = $perPage > 0 ? min(max($perPage, 1), 200) : 0;

        $world = null;
        if ($request->filled('world_id')) {
            $world = World::find((int) $worldId);
            if (!$world) return $this->returnError('World not found', 404);
        }

        $levelsQuery = Level::query();

        if ($request->filled('world_id')) {
            $levelsQuery->where('world_id', (int) $worldId);
        }

        if (!$includeInactive) {
            $levelsQuery->where('is_active', true);
        }

        if ($q !== '') {
            $levelsQuery->where(function ($qq) use ($q) {
                $qq->where('name', 'like', "%{$q}%")
                    ->orWhere('description', 'like', "%{$q}%");
            });
        }

        if ($withStages) {
            $levelsQuery->with([
                'world',
                'stages' => function ($q2) use ($includeInactive) {
                    if (!$includeInactive) {
                        $q2->where('is_active', true);
                    }
                    $q2->orderBy('order_index');
                },
            ]);
        } else {
            $levelsQuery->with('world')->withCount([
                'stages as stages_count',
                'stages as active_stages_count' => fn($q2) => $q2->where('is_active', true),
            ]);
        }

        $levelsQuery->orderBy('world_id')->orderBy('order_index');

        $levels = $perPage > 0
            ? $levelsQuery->paginate($perPage)->appends($request->query())
            : $levelsQuery->get();

        if ($world) $this->setResult('world', $world);
        $this->setResult('levels', $levels);

        return $this->returnResponse();
    }


    public function show(Request $request, int $id)
    {
        $includeInactive = $request->boolean('include_inactive', true);

        $level = Level::with(['world', 'stages' => function ($q) use ($includeInactive) {
            if (!$includeInactive) {
                $q->where('is_active', true);
            }
            $q->orderBy('order_index');
        }])->find($id);

        if (!$level) return $this->returnError('Level not found', 404);

        $this->setResult('level', $level);
        return $this->returnResponse();
    }

    public function store(StoreLevelRequest $request, int $worldId)
    {
        $world = World::find($worldId);
        if (!$world) return $this->returnError('World not found', 404);

        $data = $request->validated();

        $level = DB::transaction(function () use ($data, $worldId) {
            if (!isset($data['order_index'])) {
                $max = (int) (Level::where('world_id', $worldId)->max('order_index') ?? 0);
                $data['order_index'] = $max + 1;
            }

            $data['is_active'] = $data['is_active'] ?? true;
            $data['is_unlocked_by_default'] = $data['is_unlocked_by_default'] ?? false;

            $data['world_id'] = $worldId;

            return Level::create($data);
        });

        $this->setResult('level', $level);
        return $this->returnResponse();
    }

    public function storeGlobal(StoreLevelGlobalRequest $request)
    {
        $data = $request->validated();

        $worldId = (int) $data['world_id'];

        $world = World::find($worldId);
        if (!$world) return $this->returnError('World not found', 404);

        $level = DB::transaction(function () use ($data, $worldId) {
            if (!isset($data['order_index'])) {
                $max = (int) (Level::where('world_id', $worldId)->max('order_index') ?? 0);
                $data['order_index'] = $max + 1;
            }

            $data['is_active'] = $data['is_active'] ?? true;
            $data['is_unlocked_by_default'] = $data['is_unlocked_by_default'] ?? false;

            $data['world_id'] = $worldId;

            return Level::create($data);
        });

        $this->setResult('level', $level->load('world'));
        return $this->returnResponse();
    }

    public function update(UpdateLevelRequest $request, int $id)
    {
        $level = Level::find($id);
        if (!$level) return $this->returnError('Level not found', 404);

        $data = $request->validated();

        $level->fill($data);
        $level->save();

        $this->setResult('level', $level->fresh());
        return $this->returnResponse();
    }

    public function toggle(int $id)
    {
        $level = Level::with('world')->find($id);
        if (!$level) return $this->returnError('Level not found', 404);

        $wasActive = (bool) $level->is_active;
        $level->is_active = !$level->is_active;
        $level->save();

        if ($wasActive && !$level->is_active) {
            $this->reconcileStudentsAfterLevelDisabled($level);
        }

        $this->setResult('level', $level->fresh());
        return $this->returnResponse();
    }

    public function reorder(Request $request, int $id)
    {
        $level = Level::find($id);
        if (!$level) return $this->returnError('Level not found', 404);

        $data = $request->validate([
            'order_index' => ['required', 'integer', 'min:1'],
        ]);

        $to = (int) $data['order_index'];

        DB::transaction(function () use ($level, $to) {
            $worldId = (int) $level->world_id;

            $total = (int) Level::where('world_id', $worldId)->count();

            $to = max(1, min($to, $total));
            $from = (int) $level->order_index;

            if ($to === $from) return;

            Level::where('id', $level->id)->update(['order_index' => 0]);

            if ($to > $from) {
                Level::where('world_id', $worldId)
                    ->whereBetween('order_index', [$from + 1, $to])
                    ->decrement('order_index', 1);
            } else {
                Level::where('world_id', $worldId)
                    ->whereBetween('order_index', [$to, $from - 1])
                    ->increment('order_index', 1);
            }

            Level::where('id', $level->id)->update(['order_index' => $to]);
        });

        $this->setResult(
            'levels',
            Level::where('world_id', $level->world_id)->orderBy('order_index')->get()
        );

        return $this->returnResponse();
    }

    private function reconcileStudentsAfterLevelDisabled(Level $disabledLevel): void
    {
        $worldId = (int) $disabledLevel->world_id;

        $nextLevel = Level::where('world_id', $worldId)
            ->where('is_active', true)
            ->where('order_index', '>', $disabledLevel->order_index)
            ->orderBy('order_index')
            ->first();

        while ($nextLevel) {
            $hasActiveStage = Stage::where('level_id', $nextLevel->id)
                ->where('is_active', true)
                ->exists();

            if ($hasActiveStage) break;

            $nextLevel = Level::where('world_id', $worldId)
                ->where('is_active', true)
                ->where('order_index', '>', $nextLevel->order_index)
                ->orderBy('order_index')
                ->first();
        }

        if (!$nextLevel) {
            return;
        }

        $firstStage = Stage::where('level_id', $nextLevel->id)
            ->where('is_active', true)
            ->orderBy('order_index')
            ->first();

        if (!$firstStage) return;

        $studentIds = StudentLevelProgress::where('level_id', $disabledLevel->id)
            ->where('is_unlocked', true)
            ->where('is_completed', false)
            ->pluck('student_id');

        if ($studentIds->isEmpty()) return;

        DB::transaction(function () use ($studentIds, $nextLevel, $firstStage) {
            foreach ($studentIds as $studentId) {
                StudentLevelProgress::updateOrCreate(
                    ['student_id' => $studentId, 'level_id' => $nextLevel->id],
                    ['is_unlocked' => true, 'is_completed' => false]
                );

                $progress = StudentStageProgress::firstOrNew([
                    'student_id' => $studentId,
                    'stage_id'   => $firstStage->id,
                ]);

                if (!$progress->exists) {
                    $progress->status = 'unlocked';
                    $progress->stars_earned = 0;
                    $progress->save();
                } elseif ($progress->status === 'locked') {
                    $progress->status = 'unlocked';
                    $progress->save();
                }
            }
        });
    }
}
