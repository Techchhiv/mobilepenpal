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
        return $this->hasMany(Exercise::class)->orderBy('order_index');
    }

    public function studentProgress()
    {
        return $this->hasOne(StudentStageProgress::class)->where('student_id', auth()->id());
    }
}
