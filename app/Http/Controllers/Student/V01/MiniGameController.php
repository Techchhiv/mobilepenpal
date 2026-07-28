<?php

namespace App\Http\Controllers\Student\V01;

use App\Http\Requests\Student\V01\MiniGame\StoreMiniGameRequest;
use App\Http\Requests\Student\V01\MiniGame\UpdateMiniGameRequest;
use App\Models\MiniGame;
use App\Models\StudentMiniGamePlay;
use App\Models\SystemSetting;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MiniGameController extends Controller
{
    public function index()
    {
        $games = MiniGame::orderBy('id')->get();

        // Attach today's play counts for the authenticated student
        $studentId = auth()->id();
        $today = now()->toDateString();
        $todayPlays = StudentMiniGamePlay::where('student_id', $studentId)
            ->where('played_at', $today)
            ->pluck('play_count', 'mini_game_id');

        $gamesData = $games->map(function ($game) use ($todayPlays) {
            $data = $game->toArray();
            $data['today_play_count'] = $todayPlays[$game->id] ?? 0;
            return $data;
        });

        return $this->returnSuccess('OK', [
            'mini_games' => $gamesData,
        ]);
    }

    public function show(MiniGame $miniGame)
    {
        return $this->returnSuccess('OK', [
            'mini_game' => $miniGame,
        ]);
    }

    /**
     * Record a mini-game play for the authenticated student.
     * Returns whether they can still play (based on feature_locks limit).
     */
    public function recordPlay(Request $request): JsonResponse
    {
        $request->validate([
            'mini_game_id' => 'required|integer|exists:mini_games,id',
        ]);

        $studentId = auth()->id();
        $miniGameId = $request->input('mini_game_id');
        $today = now()->toDateString();

        // Check subscription first
        $hasSubscription = auth()->user()->hasActiveSubscription();

        if (!$hasSubscription) {
            // Check feature lock settings
            $featureLocks = SystemSetting::find('feature_locks');
            $settings = $featureLocks ? $featureLocks->value : [];
            $enabled = $settings['enabled'] ?? true;
            $dailyLimit = (int) ($settings['mini_game_free_daily_limit'] ?? 1);

            if ($enabled) {
                $record = StudentMiniGamePlay::where('student_id', $studentId)
                    ->where('mini_game_id', $miniGameId)
                    ->where('played_at', $today)
                    ->first();

                $currentCount = $record ? $record->play_count : 0;

                if ($currentCount >= $dailyLimit) {
                    return $this->returnError(__('messages.subscription_required'), 403);
                }
            }
        }

        // Increment play count
        $record = StudentMiniGamePlay::updateOrCreate(
            [
                'student_id' => $studentId,
                'mini_game_id' => $miniGameId,
                'played_at' => $today,
            ],
            []
        );
        $record->increment('play_count');

        return $this->returnSuccess('Play recorded', [
            'play_count' => $record->play_count,
        ]);
    }

    /**
     * Get today's play counts for all mini games for the authenticated student.
     */
    public function dailyPlays(): JsonResponse
    {
        $studentId = auth()->id();
        $today = now()->toDateString();

        $plays = StudentMiniGamePlay::where('student_id', $studentId)
            ->where('played_at', $today)
            ->get()
            ->keyBy('mini_game_id')
            ->map(fn($p) => $p->play_count);

        // Get feature lock daily limit
        $featureLocks = SystemSetting::find('feature_locks');
        $settings = $featureLocks ? $featureLocks->value : [];
        $dailyLimit = (int) ($settings['mini_game_free_daily_limit'] ?? 1);

        return $this->returnSuccess('OK', [
            'plays' => $plays,
            'daily_limit' => $dailyLimit,
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