<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class StudentLevelProgress extends Model
{
    use HasFactory;

    protected $guarded = [];

    public function student()
    {
        return $this->belongsTo(Student::class);
    }

    public function level()
    {
        return $this->belongsTo(Level::class);
    }
}
