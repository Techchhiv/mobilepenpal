<?php

namespace App\Helpers;

use App\Models\Student;
use App\Models\StudentLevelProgress;
use App\Models\StudentStageProgress;
use App\Models\World;
use Illuminate\Contracts\Auth\Authenticatable;

function fetchStudentProgress(Authenticatable $user): array
{
    if (!$user instanceof Student) {
        return [];
    }

    $progress = [];

    $worlds = World::where('is_active', true)->get();

    foreach ($worlds as $world) {
        $worldProgress = [
            'world_id' => $world->id,
            'world_name' => $world->name,
            'world_description' => $world->description,
            'world_image' => $world->image,
            'background_image' => $world->background_image,
            'is_completed' => $world->is_completed,
            'is_active' => $world->is_active,
            'total_lessons' => $world->levels()->count(),
            'total_stages' => $world->stages()->count(),
            'completed_lessons' => 0,
            'completed_stages' => 0,
            'total_stars' => 0,
            'remaining_lessons' => 0,
            'remaining_stages' => 0,
            'progress_percentage' => 0
        ];

        $levels = $world->levels()->orderBy('order_index')->get();

        foreach ($levels as $level) {
            $levelProgress = StudentLevelProgress::where('student_id', $user->id)
                ->where('level_id', $level->id)
                ->first();

            $stageProgress = StudentStageProgress::where('student_id', $user->id)
                ->whereIn('stage_id', $level->stages->pluck('id'))
                ->get();

            $completedStages = $stageProgress->where('status', 'completed')->count();
            $levelStars = $stageProgress->sum('stars_earned');
            $isLevelCompleted = $levelProgress ? $levelProgress->is_completed : false;

            if ($isLevelCompleted) {
                $worldProgress['completed_lessons']++;
            }

            $worldProgress['completed_stages'] += $completedStages;
            $worldProgress['total_stars'] += $levelStars;
        }

        $worldProgress['remaining_lessons'] = $worldProgress['total_lessons'] - $worldProgress['completed_lessons'];
        $worldProgress['remaining_stages'] = $worldProgress['total_stages'] - $worldProgress['completed_stages'];

        if ($worldProgress['total_stages'] > 0) {
            $worldProgress['progress_percentage'] = round(($worldProgress['completed_stages'] / $worldProgress['total_stages']) * 100, 2);
        }

        $progress[] = $worldProgress;
    }

    return $progress;
}
