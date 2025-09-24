<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Subscription extends Model
{
    use HasFactory;
     protected $fillable = [
        'school_id',
        'plan',
        'amount',
        'start_date',
        'end_date',
        'active',
    ];

    public function school()
    {
        return $this->belongsTo(School::class);
    }
}
