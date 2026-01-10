<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Classroom extends Model
{
    use HasFactory;

    protected $guarded = [];

    public function teacher()
    {
        return $this->belongsTo(Teacher::class);
    }

    public function school()
    {
        return $this->belongsTo(School::class);
    }

    public function enrollments()
    {
        return $this->hasMany(ClassroomEnrollment::class);
    }

    public function students()
    {
        return $this->belongsToMany(Student::class, 'classroom_enrollments')
            ->withPivot(['status', 'enrolled_at', 'left_at'])
            ->withTimestamps();
    }
}
