<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Builder;

class Invoice extends Model
{
    use HasFactory;

    protected $fillable = [
        'invoice_number',
        'subscription_id',
        'customer_type',
        'school_id',
        'student_id',
        'customer_name',
        'customer_email',
        'customer_phone',
        'customer_address',
        'description',
        'plan',
        'billing_period_start',
        'billing_period_end',
        'subtotal',
        'discount',
        'tax',
        'total',
        'currency',
        'status',
        'issued_at',
        'paid_at',
        'voided_at',
        'void_reason',
        'created_by',
        'voided_by',
        'pdf_path',
        'pdf_sha256',
        'idempotency_key',
    ];

    protected $casts = [
        'billing_period_start' => 'date',
        'billing_period_end'   => 'date',
        'issued_at'            => 'datetime',
        'paid_at'              => 'datetime',
        'voided_at'            => 'datetime',
        'subtotal'             => 'decimal:2',
        'discount'             => 'decimal:2',
        'tax'                  => 'decimal:2',
        'total'                => 'decimal:2',
    ];

    // ── Relationships ──────────────────────────────────────────────────────────

    public function subscription()
    {
        return $this->belongsTo(Subscription::class);
    }

    public function school()
    {
        return $this->belongsTo(School::class);
    }

    public function student()
    {
        return $this->belongsTo(Student::class);
    }

    public function payment()
    {
        return $this->hasOne(Payment::class);
    }

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function voider()
    {
        return $this->belongsTo(User::class, 'voided_by');
    }

    // ── Scopes ─────────────────────────────────────────────────────────────────

    public function scopeStatus(Builder $query, string $status): Builder
    {
        return $query->where('status', $status);
    }

    public function scopeCustomerType(Builder $query, string $type): Builder
    {
        return $query->where('customer_type', $type);
    }

    public function scopeForSchool(Builder $query, int $schoolId): Builder
    {
        return $query->where('school_id', $schoolId);
    }

    public function scopeForStudent(Builder $query, int $studentId): Builder
    {
        return $query->where('student_id', $studentId);
    }

    public function scopeIssuedBetween(Builder $query, string $from, string $to): Builder
    {
        return $query->whereBetween('issued_at', [$from, $to]);
    }

    // ── Helpers ────────────────────────────────────────────────────────────────

    public function isVoid(): bool
    {
        return $this->status === 'void';
    }

    public function isPaid(): bool
    {
        return $this->status === 'paid';
    }

    public function canBeVoided(): bool
    {
        return ! $this->isVoid();
    }
}
