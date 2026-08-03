<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class StudentExerciseAttempt extends Model
{
    use HasFactory;

    protected $guarded = [];

    protected $casts = [
        'stroke' => 'array',
    ];

    public function exercise()
    {
        return $this->belongsTo(Exercise::class);
    }

    public function student()
    {
        return $this->belongsTo(Student::class);
    }

    public function scopeForStudent($query, int $studentId)
    {
        return $query->where('student_id', $studentId);
    }

    public function scopeForDate($query, $date)
    {
        return $query->whereDate('created_at', $date);
    }

    public function scopeBetweenDates($query, $from, $to)
    {
        return $query->whereBetween('created_at', [$from, $to]);
    }
}
