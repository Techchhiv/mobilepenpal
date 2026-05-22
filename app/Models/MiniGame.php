<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class MiniGame extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'title_kh',
        'description',
        'description_kh',
        'display_type',
        'input_type',
        'is_active',
        'cover_image_url',
        'config',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'config' => 'array',
    ];
}
