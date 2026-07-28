<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class StudentMiniGamePlay extends Model
{
    protected $table = 'student_mini_game_plays';

    protected $fillable = [
        'student_id',
        'mini_game_id',
        'played_at',
        'play_count',
    ];

    protected $casts = [
        'played_at' => 'date',
        'play_count' => 'integer',
    ];

    public function student()
    {
        return $this->belongsTo(Student::class);
    }

    public function miniGame()
    {
        return $this->belongsTo(MiniGame::class);
    }
}
