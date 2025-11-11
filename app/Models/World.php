<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class World extends Model
{
    use HasFactory;

    protected $guarded = [];

    public function levels()
    {

        return $this->hasMany(Level::class);
    }

    public function stages()
    {
        return $this->hasManyThrough(Stage::class, Level::class);
    }
}
