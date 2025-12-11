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

    public function exercises()
    {
        return $this->belongsToMany(Exercise::class, StageExercise::class)
            ->withPivot(['order_index', 'repeat_count'])
            ->orderBy('stage_exercises.order_index');
    }

    public function studentProgress()
    {
        return $this->hasOne(StudentStageProgress::class)->where('student_id', auth()->id());
    }
}
