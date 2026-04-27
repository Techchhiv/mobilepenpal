<?php

namespace App\Http\Controllers\Student\V01;

use App\Models\MiniGame;

class MiniGameController extends Controller
{
    public function index()
    {
        $games = MiniGame::where('is_active', true)
            ->orderBy('id')
            ->get();

        return $this->returnSuccess('OK', [
            'mini_games' => $games,
        ]);
    }
}
