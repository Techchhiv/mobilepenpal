<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Level extends Model
{
    use HasFactory;

    protected $guarded = [];

    protected $casts = [
        'is_completed' => 'boolean',
        'is_unlocked' => 'boolean',
    ];
    public function activeStages()
    {
        return $this->hasMany(Stage::class)
            ->where('is_active', true)
            ->orderBy('order_index');
    }

    public function world()
    {
        return $this->belongsTo(World::class);
    }

    public function stages()
    {
        return $this->hasMany(Stage::class)->orderBy('order_index');
    }

    public function studentProgress()
    {
        return $this->hasOne(StudentLevelProgress::class)->where('student_id', auth()->id());
    }

    public function completedStagesProgress()
    {
        return $this->hasManyThrough(StudentStageProgress::class, Stage::class)
            ->where('student_id', auth()->id())
            ->where('status', 'completed');
    }

    public function isLockedBySubscriptionForUser($user = null): bool
    {
        $user = $user ?: auth()->user();
        if ($user && $user->hasActiveSubscription()) {
            return false;
        }

        $featureLocks = SystemSetting::find('feature_locks');
        $settings = $featureLocks ? $featureLocks->value : [];
        $enabled = $settings['enabled'] ?? true;
        if (!$enabled) {
            return false;
        }

        if ($this->is_premium || ($this->world && $this->world->is_premium)) {
            return true;
        }

        /*
        $limit = isset($settings['learning_free_stage_limit'])
            ? (int) $settings['learning_free_stage_limit']
            : (int) ($settings['learning_free_char_limit'] ?? 10);

        $worldId = $this->world_id;
        $worldOrder = $this->world?->order_index ?? 0;
        $levelOrder = $this->order_index ?? 0;

        $priorStagesCount = Stage::whereHas('level.world', function ($q) use ($worldOrder) {
            $q->where('is_active', true)->where('order_index', '<', $worldOrder);
        })->where('is_active', true)->count();

        $sameWorldPriorStagesCount = Stage::whereHas('level', function ($q) use ($worldId, $levelOrder) {
            $q->where('world_id', $worldId)->where('is_active', true)->where('order_index', '<', $levelOrder);
        })->where('is_active', true)->count();

        $globalStartStageNumber = $priorStagesCount + $sameWorldPriorStagesCount + 1;

        return $globalStartStageNumber > $limit;
        */

        return false;
    }
}
