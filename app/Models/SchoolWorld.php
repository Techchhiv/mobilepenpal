<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class SchoolWorld extends Model
{
    use HasFactory;
    protected $guarded = [];

    protected $casts = [
        'is_enabled' => 'boolean',
        'order_index' => 'integer',
    ];


    public function world()
    {
        return $this->belongsTo(World::class);
    }

    public function school()
    {
        return $this->belongsTo(School::class);
    }

    public function levels()
    {
        return $this->hasMany(Level::class, 'world_id', 'world_id');
    }

    public function activeLevels()
    {
        return $this->levels()->where('is_active', true);
    }

    public function stages()
    {
        return $this->hasManyThrough(
            Stage::class,
            Level::class,
            'world_id',   // FK on levels...
            'level_id',   // FK on stages...
            'world_id',   // local key on school_worlds
            'id'          // local key on levels
        );
    }
}
