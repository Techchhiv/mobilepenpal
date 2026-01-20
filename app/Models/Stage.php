<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Stage extends Model
{
    use HasFactory;

    protected $guarded = [];

    public function level()
    {
        return $this->belongsTo(Level::class);
    }

    public function stageExercises()
    {
        return $this->hasMany(StageExercise::class, 'stage_id');
    }

    public function exercises()
    {
        return $this->belongsToMany(Exercise::class, 'stage_exercises')
            ->withPivot(['order_index', 'repeat_count', 'is_active'])
            ->wherePivot('is_active', true)
            ->orderBy('stage_exercises.order_index');
    }

    public function studentProgress()
    {
        return $this->hasOne(StudentStageProgress::class)->where('student_id', auth()->id());
    }
}
