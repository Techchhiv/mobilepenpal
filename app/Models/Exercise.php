<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Exercise extends Model
{
    use HasFactory;

    protected $guarded = [];

    public function stage()
    {
        return $this->belongsTo(Stage::class);
    }

    public function studentAttempts()
    {
        return $this->hasMany(StudentExerciseAttempt::class);
    }
}
