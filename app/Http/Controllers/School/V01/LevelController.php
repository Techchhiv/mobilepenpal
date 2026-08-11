<?php

namespace App\Http\Controllers\School\V01;

use App\Http\Requests\School\Level\StoreLevelRequest;
use App\Http\Requests\School\Level\UpdateLevelRequest;
use App\Models\Level;
use App\Models\World;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class LevelController extends Controller
{
    public function index(Request $request, int $worldId)
    {
        $schoolId = (int) (auth()->user()->school_id ?? 0);
        if ($schoolId <= 0)
            return $this->returnError('School account required', 403);

        $includeInactive = $request->boolean('include_inactive', true);
        $withStages = $request->boolean('with_stages', false);

        $world = World::where('school_id', $schoolId)->find($worldId);
        if (!$world)
            return $this->returnError('World not found', 404);

        $q = Level::where('world_id', $worldId)->orderBy('order_index');

        if (!$includeInactive)
            $q->where('is_active', true);

        if ($withStages) {
            $q->with([
                'stages' => function ($sq) use ($includeInactive) {
                    if (!$includeInactive)
                        $sq->where('is_active', true);
                    $sq->orderBy('order_index');
                }
            ]);
        } else {
            $q->withCount([
                'stages as stages_count',
                'stages as active_stages_count' => fn($sq) => $sq->where('is_active', true),
            ]);
        }

        $levels = $q->get();

        $this->setResult('world', $world);
        $this->setResult('levels', $levels);
        return $this->returnResponse();
    }

    public function show(Request $request, int $id)
    {
        $schoolId = (int) (auth()->user()->school_id ?? 0);
        if ($schoolId <= 0)
            return $this->returnError('School account required', 403);

        $includeInactive = $request->boolean('include_inactive', true);

        $level = Level::query()
            ->where('id', $id)
            ->whereHas('world', fn($w) => $w->where('school_id', $schoolId))
            ->with([
                'world',
                'stages' => function ($sq) use ($includeInactive) {
                    if (!$includeInactive)
                        $sq->where('is_active', true);
                    $sq->orderBy('order_index');
                }
            ])
            ->first();

        if (!$level)
            return $this->returnError('Level not found', 404);

        $this->setResult('level', $level);
        return $this->returnResponse();
    }

    public function store(StoreLevelRequest $request, int $worldId)
    {
        $schoolId = (int) (auth()->user()->school_id ?? 0);
        if ($schoolId <= 0)
            return $this->returnError('School account required', 403);

        $world = World::where('school_id', $schoolId)->find($worldId);
        if (!$world)
            return $this->returnError('World not found', 404);

        $data = $request->validated();

        $level = DB::transaction(function () use ($data, $worldId) {
            if (!isset($data['order_index'])) {
                $max = (int) (Level::where('world_id', $worldId)->max('order_index') ?? 0);
                $data['order_index'] = $max + 1;
            }

            $data['world_id'] = $worldId;
            $data['is_active'] = $data['is_active'] ?? true;
            $data['is_unlocked_by_default'] = $data['is_unlocked_by_default'] ?? false;
            $data['is_premium'] = false;

            return Level::create($data);
        });

        $this->setResult('level', $level);
        return $this->returnResponse();
    }

    public function update(UpdateLevelRequest $request, int $id)
    {
        $schoolId = (int) (auth()->user()->school_id ?? 0);
        if ($schoolId <= 0)
            return $this->returnError('School account required', 403);

        $level = Level::where('id', $id)
            ->whereHas('world', fn($w) => $w->where('school_id', $schoolId))
            ->first();

        if (!$level)
            return $this->returnError('Level not found', 404);

        $data = $request->validated();

        $level->fill($data);
        $level->save();

        $this->setResult('level', $level->fresh());
        return $this->returnResponse();
    }

    public function toggle(int $id)
    {
        $schoolId = (int) (auth()->user()->school_id ?? 0);
        if ($schoolId <= 0)
            return $this->returnError('School account required', 403);

        $level = Level::where('id', $id)
            ->whereHas('world', fn($w) => $w->where('school_id', $schoolId))
            ->first();

        if (!$level)
            return $this->returnError('Level not found', 404);

        $level->is_active = !$level->is_active;
        $level->save();

        $this->setResult('level', $level->fresh());
        return $this->returnResponse();
    }

    public function reorder(Request $request, int $id)
    {
        $schoolId = (int) (auth()->user()->school_id ?? 0);
        if ($schoolId <= 0)
            return $this->returnError('School account required', 403);

        $data = $request->validate([
            'order_index' => ['required', 'integer', 'min:1'],
        ]);

        $to = (int) $data['order_index'];

        $level = Level::where('id', $id)
            ->whereHas('world', fn($w) => $w->where('school_id', $schoolId))
            ->first();

        if (!$level)
            return $this->returnError('Level not found', 404);

        DB::transaction(function () use ($level, $to) {
            $worldId = (int) $level->world_id;
            $total = (int) Level::where('world_id', $worldId)->count();

            $to = max(1, min($to, $total));
            $from = (int) $level->order_index;

            if ($to === $from)
                return;

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

        $this->setResult('levels', Level::where('world_id', $level->world_id)->orderBy('order_index')->get());
        return $this->returnResponse();
    }
}
