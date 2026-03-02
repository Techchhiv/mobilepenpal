<?php

namespace App\Http\Controllers\Admin\V01;

use App\Http\Requests\Admin\World\StoreWorldRequest;
use App\Http\Requests\Admin\World\UpdateWorldRequest;
use App\Models\Level;
use App\Models\SchoolWorld;
use App\Models\Stage;
use App\Models\Student;
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
        $audience = $request->query('audience', 'all');

        $query = World::query()
            ->whereNull('school_id')
            ->select('worlds.*')
            ->withCount([
                'levels as levels_count',
                'levels as active_levels_count' => fn($q) => $q->where('is_active', true),
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
            ->selectSub(function ($q) {
                $q->from('school_worlds')
                    ->whereColumn('school_worlds.world_id', 'worlds.id')
                    ->where('school_worlds.is_enabled', true)
                    ->selectRaw('COUNT(*)');
            }, 'assigned_schools_count')
            ->orderBy('order_index');

        if ($active === '1' || $active === 'true') {
            $query->where('is_active', true);
        } elseif ($active === '0' || $active === 'false') {
            $query->where('is_active', false);
        }

        if (in_array($audience, ['public', 'schools', 'assigned'], true)) {
            $query->where('audience', $audience);
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
            ->whereNull('school_id')
            ->whereKey($id)
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

        $assignedSchoolIds = [];
        $assignedSchools = [];

        if (($world->audience ?? null) === 'assigned') {
            $assignedSchools = SchoolWorld::query()
                ->join('schools', 'schools.id', '=', 'school_worlds.school_id')
                ->where('school_worlds.world_id', $world->id)
                ->where('school_worlds.is_enabled', true)
                ->orderBy('school_worlds.order_index')
                ->get([
                    'school_worlds.school_id',
                    'school_worlds.order_index',
                    'schools.name as school_name',
                ])
                ->map(function ($r) {
                    return [
                        'school_id' => (int) $r->school_id,
                        'name' => (string) $r->school_name,
                        'order_index' => (int) $r->order_index,
                    ];
                })
                ->values()
                ->all();

            $assignedSchoolIds = collect($assignedSchools)
                ->pluck('school_id')
                ->values()
                ->all();
        }

        $this->setResult('world', $world);
        $this->setResult('assigned_school_ids', $assignedSchoolIds);
        $this->setResult('assigned_schools', $assignedSchools);
        return $this->returnResponse();
    }


    public function store(StoreWorldRequest $request)
    {
        $data = $request->validated();

        $schoolIds = array_values(array_unique(array_map('intval', $data['school_ids'] ?? [])));
        unset($data['school_ids']);

        $world = DB::transaction(function () use ($data, $schoolIds) {
            $data['school_id'] = null;

            $data['audience'] = $data['audience'] ?? 'public';
            $data['is_active'] = $data['is_active'] ?? true;
            $data['is_premium'] = $data['is_premium'] ?? false;
            $data['is_unlocked_by_default'] = $data['is_unlocked_by_default'] ?? false;

            if (!isset($data['order_index'])) {
                $max = (int) (World::whereNull('school_id')
                    ->whereIn('audience', ['public', 'schools'])
                    ->max('order_index') ?? 0);
                $data['order_index'] = $max + 1;
            }

            $world = World::create($data);

            if ($world->audience === 'assigned' && !empty($schoolIds)) {
                foreach ($schoolIds as $sid) {
                    $next = (int) (SchoolWorld::where('school_id', $sid)->max('order_index') ?? 0) + 1;

                    SchoolWorld::updateOrCreate(
                        ['school_id' => $sid, 'world_id' => $world->id],
                        ['order_index' => $next, 'is_enabled' => true]
                    );
                }
            }

            if ($world->audience !== 'assigned') {
                SchoolWorld::where('world_id', $world->id)->update(['is_enabled' => false]);
            }

            return $world;
        });

        $this->setResult('world', $world);
        return $this->returnResponse();
    }

    public function update(UpdateWorldRequest $request, int $id)
    {
        $world = World::whereNull('school_id')->find($id);
        if (!$world)
            return $this->returnError('World not found', 404);

        $data = $request->validated();

        $schoolIds = array_values(array_unique(array_map('intval', $data['school_ids'] ?? [])));
        unset($data['school_ids']);

        DB::transaction(function () use ($world, $data, $schoolIds) {
            $world->fill($data);
            $world->save();

            if ($world->audience !== 'assigned') {
                SchoolWorld::where('world_id', $world->id)->update(['is_enabled' => false]);
            } else {
                if (!empty($schoolIds)) {
                    foreach ($schoolIds as $sid) {
                        $row = SchoolWorld::where('school_id', $sid)->where('world_id', $world->id)->first();
                        if ($row) {
                            $row->is_enabled = true;
                            $row->save();
                        } else {
                            $next = (int) (SchoolWorld::where('school_id', $sid)->max('order_index') ?? 0) + 1;
                            SchoolWorld::create([
                                'school_id' => $sid,
                                'world_id' => $world->id,
                                'order_index' => $next,
                                'is_enabled' => true,
                            ]);
                        }
                    }
                }
            }
        });

        $this->setResult('world', $world->fresh());
        return $this->returnResponse();
    }

    public function toggle(int $id)
    {
        $updated = World::whereNull('school_id')->where('id', $id)->update([
            'is_active' => DB::raw('NOT is_active'),
        ]);

        if ($updated === 0)
            return $this->returnError('World not found', 404);

        $world = World::find($id);

        $this->setResult('world', $world);
        return $this->returnResponse();
    }

    /**
     * Reorder GLOBAL list (public + schools). Assigned worlds are ordered per-school via school_worlds.
     */
    public function reorder(Request $request, int $id)
    {
        $data = $request->validate([
            'order_index' => ['required', 'integer', 'min:1'],
        ]);

        $target = (int) $data['order_index'];

        $world = World::whereNull('school_id')
            ->whereIn('audience', ['public', 'schools'])
            ->find($id);

        if (!$world)
            return $this->returnError('World not found or not reorderable globally', 404);

        DB::transaction(function () use ($world, $target) {
            $total = (int) World::whereNull('school_id')
                ->whereIn('audience', ['public', 'schools'])
                ->count();

            $newPos = max(1, min($target, $total));
            $oldPos = (int) $world->order_index;

            if ($newPos === $oldPos)
                return;

            if ($newPos < $oldPos) {
                World::whereNull('school_id')
                    ->whereIn('audience', ['public', 'schools'])
                    ->whereBetween('order_index', [$newPos, $oldPos - 1])
                    ->increment('order_index');
            } else {
                World::whereNull('school_id')
                    ->whereIn('audience', ['public', 'schools'])
                    ->whereBetween('order_index', [$oldPos + 1, $newPos])
                    ->decrement('order_index');
            }

            $world->order_index = $newPos;
            $world->save();
        });

        $this->setResult('worlds', World::whereNull('school_id')->orderBy('order_index')->get());
        return $this->returnResponse();
    }

    public function assignToSchools(Request $request, int $id)
    {
        $data = $request->validate([
            'school_ids' => ['required', 'array', 'min:1'],
            'school_ids.*' => ['integer', 'exists:schools,id'],
        ]);

        $world = World::whereNull('school_id')->find($id);
        if (!$world)
            return $this->returnError('World not found', 404);

        DB::transaction(function () use ($world, $data) {
            $world->audience = 'assigned';
            $world->save();

            foreach ($data['school_ids'] as $sid) {
                $sid = (int) $sid;

                $row = SchoolWorld::where('school_id', $sid)->where('world_id', $world->id)->first();
                if ($row) {
                    $row->is_enabled = true;
                    $row->save();
                    continue;
                }

                $next = (int) (SchoolWorld::where('school_id', $sid)->max('order_index') ?? 0) + 1;

                SchoolWorld::create([
                    'school_id' => $sid,
                    'world_id' => $world->id,
                    'order_index' => $next,
                    'is_enabled' => true,
                ]);
            }
        });

        $this->setResult('world', $world->fresh());
        return $this->returnResponse();
    }

    public function unassignFromSchools(Request $request, int $id)
    {
        $data = $request->validate([
            'school_ids' => ['required', 'array', 'min:1'],
            'school_ids.*' => ['integer', 'exists:schools,id'],
        ]);

        $world = World::whereNull('school_id')->find($id);
        if (!$world)
            return $this->returnError('World not found', 404);

        SchoolWorld::where('world_id', $world->id)
            ->whereIn('school_id', array_map('intval', $data['school_ids']))
            ->update(['is_enabled' => false]);

        $this->setResult('world', $world->fresh());
        return $this->returnResponse();
    }

    /**
     * Reorder within ONE school's stack (school_worlds.order_index).
     */
    public function reorderForSchool(Request $request, int $id)
    {
        $data = $request->validate([
            'school_id' => ['required', 'integer', 'exists:schools,id'],
            'order_index' => ['required', 'integer', 'min:1'],
        ]);

        $schoolId = (int) $data['school_id'];
        $to = (int) $data['order_index'];

        $world = World::whereNull('school_id')->find($id);
        if (!$world)
            return $this->returnError('World not found', 404);

        $row = SchoolWorld::where('school_id', $schoolId)
            ->where('world_id', $world->id)
            ->where('is_enabled', true)
            ->first();

        if (!$row)
            return $this->returnError('World is not assigned to this school', 404);

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
        $this->setResult('world_id', $world->id);
        return $this->returnResponse();
    }

    public function unlockForStudent(Request $request, int $id)
    {
        $data = $request->validate([
            'student_id' => ['required', 'integer', 'exists:students,id'],
        ]);

        $studentId = (int) $data['student_id'];

        $studentSchoolId = (int) (Student::whereKey($studentId)->value('school_id') ?? 0);
        $studentHasSchool = $studentSchoolId > 0;

        $world = World::query()
            ->where('id', $id)
            ->where('is_active', true)
            ->where(function ($q) use ($studentSchoolId, $studentHasSchool) {

                $q->where(function ($qq) use ($studentSchoolId) {
                    $qq->whereNotNull('school_id')
                        ->where('school_id', $studentSchoolId);
                })

                    ->orWhere(function ($qq) use ($studentSchoolId, $studentHasSchool) {
                        $qq->whereNull('school_id')
                            ->where(function ($aud) use ($studentSchoolId, $studentHasSchool) {
                                $aud->where('audience', 'public')
                                    ->orWhere(function ($a) use ($studentHasSchool) {
                                        $a->where('audience', 'schools')
                                            ->whereRaw($studentHasSchool ? '1=1' : '1=0');
                                    })
                                    ->orWhere(function ($a) use ($studentSchoolId, $studentHasSchool) {
                                        $a->where('audience', 'assigned')
                                            ->whereRaw($studentHasSchool ? '1=1' : '1=0')
                                            ->whereExists(function ($sub) use ($studentSchoolId) {
                                                $sub->from('school_worlds')
                                                    ->whereColumn('school_worlds.world_id', 'worlds.id')
                                                    ->where('school_worlds.school_id', $studentSchoolId)
                                                    ->where('school_worlds.is_enabled', true);
                                            });
                                    });
                            });
                    });
            })
            ->first();

        if (!$world) {
            return $this->returnError('World not accessible for this student', 403);
        }

        DB::transaction(function () use ($studentId, $world) {
            $worldProgress = StudentWorldProgress::firstOrNew([
                'student_id' => $studentId,
                'world_id' => $world->id,
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
                'level_id' => $firstLevel->id,
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
                'stage_id' => $firstStage->id,
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
