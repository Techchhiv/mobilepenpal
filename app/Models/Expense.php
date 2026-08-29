<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Expense extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'amount',
        'currency',
        'category',
        'spent_at',
        'recorded_by',
        'notes',
    ];

    protected $casts = [
        'amount'   => 'decimal:2',
        'spent_at' => 'date',
    ];

    public function recorder()
    {
        return $this->belongsTo(User::class, 'recorded_by');
    }
}
