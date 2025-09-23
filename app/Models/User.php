<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Spatie\Permission\Traits\HasRoles;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable, HasRoles;
    use HasApiTokens, HasFactory, Notifiable, HasRoles;

    protected $guard_name = 'api'; // ✅ match Spatie + routes

    protected $fillable = ['name','email','password','google_id'];
    protected $hidden = ['password','remember_token'];
    protected $casts  = ['email_verified_at' => 'datetime'];

}
