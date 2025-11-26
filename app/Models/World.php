<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class World extends Model
{
    use HasFactory;

    protected $guarded = [];

    public function levels()
    {

        return $this->hasMany(Level::class)->orderBy('order_index');
    }

    public function stages()
    {
        return $this->hasManyThrough(Stage::class, Level::class);
    }

    public function studentProgress()
    {
        return $this->hasOne(StudentWorldProgress::class)->where('student_id', auth()->id());
    }

    public function studentLevelProgress()
    {
        return $this->hasManyThrough(StudentLevelProgress::class, Level::class)
            ->where('student_id', auth()->id());
    }
}
