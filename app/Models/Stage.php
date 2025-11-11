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
        return $this->hasMany(Exercise::class);
    }

    public function studentProgress()
    {
        return $this->hasMany(StudentStageProgress::class);
    }
}
