<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Sanctum\HasApiTokens;
use Spatie\Permission\Traits\HasRoles;

class Teacher extends Authenticatable
{
    use HasApiTokens, HasFactory, HasRoles;

    // protected $table = 'teachers';

    // protected $guard_name = "teachers";

    protected $guarded = [];

    // protected $fillable = [
    //     'school_id',
    //     'teacher_id',
    //     'name',
    //     'email',
    //     'phone',
    //     'subject',
    //     'photo',
    //     'is_active',
    //     'school_key','is_online','last_seen_at',
    // ];

    protected $hidden = ['password'];

    protected $casts = [
        'is_active' => 'boolean',
    ];


    public function school()
    {
        return $this->belongsTo(School::class, 'school_id');
    }

    public function branch()
    {
        return $this->belongsTo(Branch::class);
    }
}
