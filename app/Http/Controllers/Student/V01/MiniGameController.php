<?php

namespace App\Http\Controllers\Student\V01;

use App\Http\Requests\Student\V01\MiniGame\StoreMiniGameRequest;
use App\Http\Requests\Student\V01\MiniGame\UpdateMiniGameRequest;
use App\Models\MiniGame;

class MiniGameController extends Controller
{
    public function index()
    {
        $games = MiniGame::orderBy('id')->get();

        return $this->returnSuccess('OK', [
            'mini_games' => $games,
        ]);
    }

    public function show(MiniGame $miniGame)
    {
        return $this->returnSuccess('OK', [
            'mini_game' => $miniGame,
        ]);
    }

    public function store(StoreMiniGameRequest $request)
    {
        $miniGame = MiniGame::create($request->data());

        return $this->returnSuccess('Mini game created successfully', [
            'mini_game' => $miniGame,
        ]);
    }

    public function update(UpdateMiniGameRequest $request, MiniGame $miniGame)
    {
        $miniGame->update($request->data($miniGame->cover_image_url));

        return $this->returnSuccess('Mini game updated successfully', [
            'mini_game' => $miniGame->fresh(),
        ]);
    }

    public function destroy(MiniGame $miniGame)
    {
        $miniGame->delete();

        return $this->returnSuccess('Mini game deleted successfully', []);
    }
}