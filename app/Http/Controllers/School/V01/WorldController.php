<?php

namespace App\Http\Controllers\School\V01;

use App\Http\Requests\School\World\StoreWorldRequest;
use App\Http\Requests\School\World\UpdateWorldRequest;
use App\Models\Level;
use App\Models\SchoolWorld;
use App\Models\Stage;
use App\Models\World;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class WorldController extends Controller
{
    /**
     * GET /school/worlds
     * Returns:
     * - global_worlds: admin-owned (public/schools) with per-school hidden flag
     * - school_stack: enabled worlds in this school's stack (assigned + school-owned), ordered by pivot order
     */
    public function index(Request $request)
    {
        $schoolId = (int) (auth()->user()->school_id ?? 0);
        if ($schoolId <= 0)
            return $this->returnError('School account required', 403);

        $includeInactive = $request->boolean('include_inactive', true);

        $global = World::query()
            ->whereNull('school_id')
            ->whereIn('audience', ['schools'])
            ->when(!$includeInactive, fn($q) => $q->where('is_active', true))
            ->select('worlds.*')
            ->selectSub(function ($q) use ($schoolId) {
                $q->from('school_worlds')
                    ->whereColumn('school_worlds.world_id', 'worlds.id')
                    ->where('school_worlds.school_id', $schoolId)
                    ->where('school_worlds.is_enabled', false)
                    ->selectRaw('1');
            }, 'is_hidden_for_school')
            ->withCount([
                'levels as active_levels_count' => fn($q) => $q->where('is_active', true),
            ])
            ->selectSub(function ($q) {
                $q->from('stages')
                    ->join('levels', 'levels.id', '=', 'stages.level_id')
                    ->whereColumn('levels.world_id', 'worlds.id')
                    ->where('levels.is_active', true)
                    ->where('stages.is_active', true)
                    ->selectRaw('COUNT(*)');
            }, 'active_stages_count')
            ->orderBy('order_index')
            ->get()
            ->map(function ($w) {
                $w->is_hidden_for_school = !empty($w->is_hidden_for_school);
                return $w;
            });

        $stack = SchoolWorld::query()
            ->where('school_worlds.school_id', $schoolId)
            ->where('school_worlds.is_enabled', true)
            ->join('worlds', 'worlds.id', '=', 'school_worlds.world_id')
            ->where(function ($q) use ($schoolId) {
                $q->where('worlds.school_id', $schoolId)
                    ->orWhere(function ($qq) {
                        $qq->whereNull('worlds.school_id')
                            ->where('worlds.audience', 'assigned'); // ✅ admin-assigned only
                    });
            })
            ->when(!$includeInactive, fn($q) => $q->where('worlds.is_active', true))
            ->select('worlds.*')
            ->addSelect(['stack_order_index' => DB::raw('school_worlds.order_index')])
            ->withCount([
                'levels as active_levels_count' => fn($q) => $q->where('is_active', true),
            ])
            ->selectSub(function ($q) {
                $q->from('stages')
                    ->join('levels', 'levels.id', '=', 'stages.level_id')
                    ->whereColumn('levels.world_id', 'worlds.id')
                    ->where('levels.is_active', true)
                    ->where('stages.is_active', true)
                    ->selectRaw('COUNT(*)');
            }, 'active_stages_count')
            ->orderBy('school_worlds.order_index')
            ->get()
            ->map(function ($w) use ($schoolId) {
                $w->stack_order_index = (int) ($w->stack_order_index ?? 0);
                $w->owned_by_school = (int) ($w->school_id ?? 0) === (int) $schoolId;
                $w->active_stages_count = (int) ($w->active_stages_count ?? 0);
                return $w;
            });

        $this->setResult('global_worlds', $global);
        $this->setResult('school_stack', $stack);
        return $this->returnResponse();
    }

    /**
     * GET /school/worlds/{id}
     * School can view:
     * - its own world
     * - admin global worlds
     * - admin assigned worlds (if pivot exists for this school, enabled or disabled)
     */
    public function show(Request $request, int $id)
    {
        $schoolId = (int) (auth()->user()->school_id ?? 0);
        if ($schoolId <= 0)
            return $this->returnError('School account required', 403);

        $includeInactive = $request->boolean('include_inactive', true);
        $withStages = $request->boolean('with_stages', false);

        $world = World::query()
            ->where('id', $id)
            ->with([
                'levels' => function ($q) use ($includeInactive, $withStages) {
                    if (!$includeInactive)
                        $q->where('is_active', true);
                    $q->orderBy('order_index');

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
                }
            ])
            ->first();

        if (!$world)
            return $this->returnError('World not found', 404);

        if (!is_null($world->school_id)) {
            if ((int) $world->school_id !== $schoolId) {
                return $this->returnError('World not found', 404);
            }

            $meta = [
                'owned_by_school' => true,
                'is_admin_owned' => false,
                'audience' => (string) ($world->audience ?? 'assigned'),
                'is_global' => false,
                'is_assigned' => false,
                'is_hidden_for_school' => false,
                'is_enabled_for_school' => true,
                'stack_order_index' => null,
                'can_edit' => true,
            ];

            $this->setResult('world', $world);
            $this->setResult('meta', $meta);
            return $this->returnResponse();
        }

        $pivot = SchoolWorld::where('school_id', $schoolId)
            ->where('world_id', $world->id)
            ->first();

        if ($world->audience === 'public') {
            return $this->returnError('World not found', 404);
        }

        $isAdminOwned = true;
        $isGlobal = $world->audience === 'schools';
        $isAssigned = $world->audience === 'assigned';

        if ($isAssigned) {
            if (!$pivot || $pivot->is_enabled !== true) {
                return $this->returnError('World not found', 404);
            }
        }

        if ($isGlobal && $pivot && $pivot->is_enabled === false) {
            return $this->returnError('World not found', 404);
        }

        $meta = [
            'owned_by_school' => false,
            'is_admin_owned' => $isAdminOwned,
            'audience' => (string) ($world->audience ?? 'schools'),
            'is_global' => $isGlobal,
            'is_assigned' => $isAssigned,
            'is_hidden_for_school' => $isGlobal && $pivot ? ($pivot->is_enabled === false) : false,
            'is_enabled_for_school' => $pivot ? (bool) $pivot->is_enabled : true,
            'stack_order_index' => ($pivot && $pivot->is_enabled) ? (int) $pivot->order_index : null,
            'can_edit' => false, // admin-owned not editable by school
        ];

        $this->setResult('world', $world);
        $this->setResult('meta', $meta);
        return $this->returnResponse();
    }

    /**
     * POST /school/worlds
     * Creates a school-owned world and appends it to school stack.
     */
    public function store(StoreWorldRequest $request)
    {
        $schoolId = (int) (auth()->user()->school_id ?? 0);
        if ($schoolId <= 0)
            return $this->returnError('School account required', 403);

        $data = $request->validated();

        $world = DB::transaction(function () use ($data, $schoolId) {
            $nextWorldOrder = (int) (World::where('school_id', $schoolId)->max('order_index') ?? 0) + 1;
            $nextStackOrder = (int) (SchoolWorld::where('school_id', $schoolId)->max('order_index') ?? 0) + 1;

            $w = World::create([
                'school_id' => $schoolId,
                'audience' => 'assigned',
                'name' => $data['name'],
                'description' => $data['description'] ?? null,
                'name_en' => $data['name_en'],
                'description_en' => $data['description_en'] ?? null,
                'order_index' => $nextWorldOrder,
                'is_active' => $data['is_active'] ?? true,
                'is_unlocked_by_default' => $data['is_unlocked_by_default'] ?? false,
                'is_premium' => false,
            ]);

            SchoolWorld::updateOrCreate(
                ['school_id' => $schoolId, 'world_id' => $w->id],
                ['order_index' => $nextStackOrder, 'is_enabled' => true]
            );

            return $w;
        });

        $this->setResult('world', $world);
        return $this->returnResponse();
    }

    /**
     * PUT /school/worlds/{id}
     * Only updates a school-owned world.
     */
    public function update(UpdateWorldRequest $request, int $id)
    {
        $schoolId = (int) (auth()->user()->school_id ?? 0);
        if ($schoolId <= 0)
            return $this->returnError('School account required', 403);

        $world = World::where('school_id', $schoolId)->find($id);
        if (!$world)
            return $this->returnError('World not found', 404);

        $data = $request->validated();

        $world->fill($data);
        $world->save();

        $this->setResult('world', $world->fresh());
        return $this->returnResponse();
    }

    /**
     * PUT /school/worlds/{id}/toggle
     *
     * Behavior:
     * - If school-owned: toggles worlds.is_active
     * - If admin global (public/schools): toggles "hidden for this school" via school_worlds override row (is_enabled=false)
     * - If admin assigned: toggles pivot is_enabled (enable/disable for this school)
     */
    public function toggle(Request $request, int $id)
    {
        $schoolId = (int) (auth()->user()->school_id ?? 0);
        if ($schoolId <= 0)
            return $this->returnError('School account required', 403);

        $world = World::find($id);
        if (!$world)
            return $this->returnError('World not found', 404);

        if ((int) ($world->school_id ?? 0) === $schoolId) {
            $world->is_active = !$world->is_active;
            $world->save();

            $this->setResult('world', $world->fresh());
            return $this->returnResponse();
        }

        if (!is_null($world->school_id) && (int) $world->school_id !== $schoolId) {
            return $this->returnError('World not found', 404);
        }

        $isGlobal = is_null($world->school_id) && in_array($world->audience, ['public', 'schools'], true);
        $isAssigned = is_null($world->school_id) && $world->audience === 'assigned';

        if ($isGlobal) {
            $row = SchoolWorld::where('school_id', $schoolId)->where('world_id', $world->id)->first();

            if ($row && $row->is_enabled === false) {
                $row->delete();
                $this->setResult('hidden', false);
            } else {
                $next = (int) (SchoolWorld::where('school_id', $schoolId)->max('order_index') ?? 0) + 1;

                SchoolWorld::updateOrCreate(
                    ['school_id' => $schoolId, 'world_id' => $world->id],
                    ['order_index' => $row?->order_index ?? $next, 'is_enabled' => false]
                );

                $this->setResult('hidden', true);
            }

            $this->setResult('world', $world);
            return $this->returnResponse();
        }

        if ($isAssigned) {
            $row = SchoolWorld::where('school_id', $schoolId)->where('world_id', $world->id)->first();
            if (!$row)
                return $this->returnError('World is not assigned to this school', 404);

            $row->is_enabled = !$row->is_enabled;
            $row->save();

            $this->setResult('enabled', (bool) $row->is_enabled);
            $this->setResult('world', $world);
            return $this->returnResponse();
        }

        return $this->returnError('Unsupported world type', 422);
    }

    /**
     * PUT /school/worlds/{id}/reorder
     * Reorder within this school's stack (school_worlds.order_index) for enabled worlds.
     */
    public function reorder(Request $request, int $id)
    {
        $schoolId = (int) (auth()->user()->school_id ?? 0);
        if ($schoolId <= 0)
            return $this->returnError('School account required', 403);

        $data = $request->validate([
            'order_index' => ['required', 'integer', 'min:1'],
        ]);

        $to = (int) $data['order_index'];

        $row = SchoolWorld::where('school_id', $schoolId)
            ->where('world_id', $id)
            ->where('is_enabled', true)
            ->first();

        if (!$row)
            return $this->returnError('World is not in school stack (or disabled)', 404);

        DB::transaction(function () use ($row, $schoolId, $to) {
            $total = (int) SchoolWorld::where('school_id', $schoolId)
                ->where('is_enabled', true)
                ->count();

            $to = max(1, min($to, $total));
            $from = (int) $row->order_index;

            if ($to === $from)
                return;

            SchoolWorld::where('id', $row->id)->update(['order_index' => 0]);

            if ($to > $from) {
                SchoolWorld::where('school_id', $schoolId)->where('is_enabled', true)
                    ->whereBetween('order_index', [$from + 1, $to])
                    ->decrement('order_index', 1);
            } else {
                SchoolWorld::where('school_id', $schoolId)->where('is_enabled', true)
                    ->whereBetween('order_index', [$to, $from - 1])
                    ->increment('order_index', 1);
            }

            SchoolWorld::where('id', $row->id)->update(['order_index' => $to]);
        });

        $this->setResult('school_id', $schoolId);
        $this->setResult('world_id', $id);
        $this->setResult('order_index', $to);
        return $this->returnResponse();
    }
}
