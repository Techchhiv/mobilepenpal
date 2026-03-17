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
        'firebase_uid'
    ];

    protected $casts = [
        // 'date_of_birth' => 'date',
        'enrollment_year' => 'integer',
        'unlocked_avatars' => 'array',
    ];

    public function levelProgress()
    {
        return $this->hasMany(StudentLevelProgress::class);
    }

    public function stageProgress()
    {
        return $this->hasMany(StudentStageProgress::class);
    }

    public function exerciseAttempts()
    {
        return $this->hasMany(StudentExerciseAttempt::class);
    }

    public function subscriptions()
    {
        return $this->hasMany(Subscription::class);
    }

    public function school()
    {
        return $this->belongsTo(School::class);
    }

    public function getActiveSubscription()
    {
        if ($this->school_id) {
            return Subscription::where('school_id', $this->school_id)
                ->where('active', true)
                ->where('start_date', '<=', now())
                ->where('end_date', '>=', now())
                ->first();
        }

        return $this->subscriptions()
            ->where('active', true)
            ->where('start_date', '<=', now())
            ->where('end_date', '>=', now())
            ->first();
    }

    public function hasActiveSubscription(): bool
    {
        return $this->getActiveSubscription() !== null;
    }
}
