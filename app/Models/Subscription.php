<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Subscription extends Model
{
    use HasFactory;

    protected $fillable = [
        'school_id',
        'student_id',
        'plan',
        'amount',
        'start_date',
        'end_date',
        'active',
        'idempotency_key',
    ];

    protected $casts = [
        'start_date' => 'date',
        'end_date' => 'date',
        'active' => 'boolean',
        'amount' => 'decimal:2',
    ];

    public function school()
    {
        return $this->belongsTo(School::class);
    }

    public function student()
    {
        return $this->belongsTo(Student::class);
    }

    public function invoice()
    {
        return $this->hasOne(Invoice::class);
    }

    /**
     * Scope query to currently active unexpired subscriptions.
     */
    public function scopeActive($query)
    {
        $today = now()->toDateString();
        return $query->where('active', true)
            ->where('start_date', '<=', $today)
            ->where('end_date', '>=', $today);
    }

    /**
     * Check if this subscription instance is currently active on the given date.
     */
    public function isCurrentlyActive(?string $date = null): bool
    {
        $checkDate = $date ?? now()->toDateString();
        $start = $this->start_date ? $this->start_date->toDateString() : null;
        $end = $this->end_date ? $this->end_date->toDateString() : null;

        return (bool) $this->active
            && (! $start || $start <= $checkDate)
            && (! $end || $end >= $checkDate);
    }
}
