<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Level extends Model
{
    use HasFactory;

    protected $guarded = [];

    public function world()
    {
        return $this->belongsTo(World::class);
    }

    public function stages()
    {
        return $this->hasMany(Stage::class);
    }

    public function studentProgress()
    {
        return $this->hasMany(StudentLevelProgress::class);
    }
}
