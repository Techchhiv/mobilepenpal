<?php

namespace App\Http\Controllers\Admin\V01;

use App\Http\Requests\Admin\World\StoreWorldRequest;
use App\Http\Requests\Admin\World\UpdateWorldRequest;
use App\Models\Level;
use App\Models\Stage;
use App\Models\StudentLevelProgress;
use App\Models\StudentStageProgress;
use App\Models\StudentWorldProgress;
use App\Models\World;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class WorldController extends Controller
{
    public function index(Request $request)
    {
        $active = $request->query('active', 'all');

        $query = World::query()
            ->select('worlds.*')
            ->withCount([
                'levels as levels_count',
                'levels as active_levels_count' => function ($q) {
                    $q->where('is_active', true);
                },
            ])
            ->selectSub(function ($q) {
                $q->from('stages')
                    ->join('levels', 'levels.id', '=', 'stages.level_id')
                    ->whereColumn('levels.world_id', 'worlds.id')
                    ->selectRaw('COUNT(*)');
            }, 'stages_count')
            ->selectSub(function ($q) {
                $q->from('stages')
                    ->join('levels', 'levels.id', '=', 'stages.level_id')
                    ->whereColumn('levels.world_id', 'worlds.id')
                    ->where('levels.is_active', true)
                    ->where('stages.is_active', true)
                    ->selectRaw('COUNT(*)');
            }, 'active_stages_count')
            ->orderBy('order_index');

        if ($active === '1' || $active === 'true') {
            $query->where('is_active', true);
        } elseif ($active === '0' || $active === 'false') {
            $query->where('is_active', false);
        }

        $worlds = $query->get();

        $this->setResult('worlds', $worlds);
        return $this->returnResponse();
    }

    public function show(Request $request, int $id)
    {
        $includeInactive = $request->boolean('include_inactive', true);
        $withStages = $request->boolean('with_stages', false);

        $world = World::query()
            ->where('id', $id)
            ->with(['levels' => function ($q) use ($includeInactive, $withStages) {
                if (!$includeInactive) $q->where('is_active', true);
                $q->orderBy('order_index');

                if ($withStages) {
                    $q->with(['stages' => function ($sq) use ($includeInactive) {
                        if (!$includeInactive) $sq->where('is_active', true);
                        $sq->orderBy('order_index');
                    }]);
                } else {
                    $q->withCount([
                        'stages as stages_count',
                        'stages as active_stages_count' => fn($sq) => $sq->where('is_active', true),
                    ]);
                }
            }])
            ->first();

        if (!$world) return $this->returnError('World not found', 404);

        $this->setResult('world', $world);
        return $this->returnResponse();
    }

    public function store(StoreWorldRequest $request)
    {
        $data = $request->validated();

        $world = DB::transaction(function () use ($data) {
            if (!isset($data['order_index'])) {
                $max = (int) (World::max('order_index') ?? 0);
                $data['order_index'] = $max + 1;
            }

            $data['is_active'] = $data['is_active'] ?? true;
            $data['is_unlocked_by_default'] = $data['is_unlocked_by_default'] ?? false;

            return World::create($data);
        });

        $this->setResult('world', $world);
        return $this->returnResponse();
    }

    public function update(UpdateWorldRequest $request, int $id)
    {
        $world = World::find($id);
        if (!$world) return $this->returnError('World not found', 404);

        $world->fill($request->validated());
        $world->save();

        $this->setResult('world', $world->fresh());
        return $this->returnResponse();
    }

    public function toggle(int $id)
    {
        $updated = World::where('id', $id)->update([
            'is_active' => DB::raw('NOT is_active'),
        ]);

        if ($updated === 0) {
            return $this->returnError('World not found', 404);
        }

        $world = World::find($id);

        $this->setResult('world', $world);
        return $this->returnResponse();
    }


    public function reorder(Request $request, int $id)
    {
        $data = $request->validate([
            'order_index' => ['required', 'integer', 'min:1'],
        ]);

        $target = (int) $data['order_index'];

        $world = World::find($id);
        if (!$world) return $this->returnError('World not found', 404);

        DB::transaction(function () use ($world, $target) {
            $total = (int) World::count();

            $newPos = max(1, min($target, $total));
            $oldPos = (int) $world->order_index;

            if ($newPos === $oldPos) {
                return;
            }

            if ($newPos < $oldPos) {
                World::whereBetween('order_index', [$newPos, $oldPos - 1])
                    ->increment('order_index');
            } else {
                World::whereBetween('order_index', [$oldPos + 1, $newPos])
                    ->decrement('order_index');
            }

            $world->order_index = $newPos;
            $world->save();
        });

        $this->setResult('worlds', World::orderBy('order_index')->get());
        return $this->returnResponse();
    }

    public function unlockForStudent(Request $request, int $id)
    {
        $data = $request->validate([
            'student_id' => ['required', 'integer', 'exists:students,id'],
        ]);

        $studentId = (int) $data['student_id'];

        $world = World::find($id);
        if (!$world) {
            return $this->returnError('World not found', 404);
        }

        DB::transaction(function () use ($studentId, $world) {
            $worldProgress = StudentWorldProgress::firstOrNew([
                'student_id' => $studentId,
                'world_id'   => $world->id,
            ]);

            if (!$worldProgress->exists) {
                $worldProgress->is_completed = false;
                $worldProgress->completion_percentage = 0;
                $worldProgress->total_stars_earned = 0;
            }

            $worldProgress->is_unlocked = true;
            $worldProgress->save();

            $firstLevel = Level::where('world_id', $world->id)
                ->where('is_active', true)
                ->orderBy('order_index')
                ->first();

            if (!$firstLevel) {
                return;
            }

            $levelProgress = StudentLevelProgress::firstOrNew([
                'student_id' => $studentId,
                'level_id'   => $firstLevel->id,
            ]);

            if (!$levelProgress->exists) {
                $levelProgress->is_completed = false;
                $levelProgress->total_stars = 0;
            }

            $levelProgress->is_unlocked = true;
            $levelProgress->save();

            $firstStage = Stage::where('level_id', $firstLevel->id)
                ->where('is_active', true)
                ->orderBy('order_index')
                ->first();

            if (!$firstStage) {
                return;
            }

            $stageProgress = StudentStageProgress::firstOrNew([
                'student_id' => $studentId,
                'stage_id'   => $firstStage->id,
            ]);

            if (!$stageProgress->exists) {
                $stageProgress->stars_earned = 0;
            }

            if ($stageProgress->status === null || $stageProgress->status === 'locked') {
                $stageProgress->status = 'unlocked';
            }

            $stageProgress->save();
        });

        $this->setResult('world', $world->fresh());
        $this->setResult('student_id', $studentId);
        return $this->returnResponse();
    }
}
