<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Payment extends Model
{
    use HasFactory;

    public const METHOD_CASH          = 'cash';
    public const METHOD_BANK_TRANSFER = 'bank_transfer';
    public const METHOD_BAKONG        = 'bakong';
    public const METHOD_OTHER         = 'other';

    public const METHODS = [
        self::METHOD_CASH          => 'Cash',
        self::METHOD_BANK_TRANSFER => 'Bank Transfer',
        self::METHOD_BAKONG        => 'Bakong KHQR',
        self::METHOD_OTHER         => 'Other',
    ];

    protected $fillable = [
        'invoice_id',
        'amount',
        'currency',
        'payment_method',
        'payment_reference',
        'status',
        'paid_at',
        'recorded_by',
        'notes',
    ];

    protected $casts = [
        'amount'  => 'decimal:2',
        'paid_at' => 'datetime',
    ];

    // ── Relationships ──────────────────────────────────────────────────────────

    public function invoice()
    {
        return $this->belongsTo(Invoice::class);
    }

    public function recorder()
    {
        return $this->belongsTo(User::class, 'recorded_by');
    }
}
