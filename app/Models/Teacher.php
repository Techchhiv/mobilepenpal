<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Teacher extends Model
{
    use HasFactory;

    protected $table = 'teachers';

    protected $fillable = [
        'school_id',
        'teacher_id',
        'name',
        'email',
        'phone',
        'subject',
        'photo',
        'is_active',
        'school_key','is_online','last_seen_at',
    ];

    public function school()
    {
        return $this->belongsTo(School::class, 'school_id');
    }
}
