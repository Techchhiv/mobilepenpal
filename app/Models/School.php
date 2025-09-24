<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class School extends Model
{
    use HasFactory;
    protected $fillable = [
        'name',
        'slug',
        'school_key',
        'admin_email',
        'is_active',
    ];

    public function admin()
    {
        return $this->hasOne(User::class)->whereHas('roles', function ($q) {
            $q->where('name', 'school-admin');
        });
    }

    public function users()
    {
        return $this->hasMany(User::class);
    }
    public function subscriptions()
    {
        return $this->hasMany(Subscription::class);
    }
}
