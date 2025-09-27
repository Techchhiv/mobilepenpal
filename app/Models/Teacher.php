<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class Teacher extends Authenticatable
{
    use HasFactory, Notifiable, HasApiTokens;


protected $table = 'teachers';
    protected $fillable = [
        'school_id',
        'teacher_id',
        'name',
        'email',
        'phone',
        'subject',
        'photo',
        'password',
        'school_key',
    ];

    protected $hidden = [
        'password',
    ];

    public function school()
    {
        return $this->belongsTo(School::class, 'school_id');
    }
}
