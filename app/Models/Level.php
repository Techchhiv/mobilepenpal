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
}
