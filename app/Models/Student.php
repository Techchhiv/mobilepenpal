<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Database\Eloquent\Model;
use Laravel\Sanctum\HasApiTokens;
use Spatie\Permission\Traits\HasRoles;

class Student extends Authenticatable
{
    use HasApiTokens, HasFactory, HasRoles;

    protected $guarded = [];

    protected $hidden = [
        'password',
    ];

     protected $casts = [
        'date_of_birth' => 'date',
        'enrollment_year' => 'date',
    ];
}
