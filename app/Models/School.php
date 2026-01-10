<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

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

    protected $casts = [
        'is_active' => 'boolean',
    ];

    // Auto-generate slug & school_key if not provided
    protected static function booted()
    {
        static::creating(function (School $school) {
            // slug
            if (blank($school->slug) && filled($school->name)) {
                $base = Str::slug($school->name);
                $slug = $base;
                $i = 1;
                while (self::where('slug', $slug)->exists()) {
                    $slug = $base . '-' . $i++;
                }
                $school->slug = $slug;
            }

            // school_key (UUID)
            if (blank($school->school_key)) {
                $key = (string) Str::uuid();
                // ultra defensive uniqueness check
                while (self::where('school_key', $key)->exists()) {
                    $key = (string) Str::uuid();
                }
                $school->school_key = $key;
            }

            // default active if not set
            if (is_null($school->is_active)) {
                $school->is_active = true;
            }
        });
    }

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

    public function branches(){
        return $this->hasMany(Branch::class);
    }
}
