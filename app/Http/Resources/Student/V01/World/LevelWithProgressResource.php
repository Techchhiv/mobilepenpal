<?php

namespace App\Http\Resources\Student\V01\World;

use Illuminate\Http\Resources\Json\JsonResource;

class LevelWithProgressResource extends JsonResource
{
    public function toArray($request)
    {
        $totalStages = $this->stages->count();
        $completedStages = $this->completedStagesProgress->count();

        $isPremium = (bool) $this->is_premium;
        $hasSubscription = auth()->user()?->hasActiveSubscription() ?? false;

        // A level is also locked if its parent world is premium
        $worldPremium = (bool) ($this->world?->is_premium ?? false);
        $isLockedBySub = ($isPremium || $worldPremium) && !$hasSubscription;

        return [
            'id' => (int) $this->id,

            'name' => $this->name,
            'name_en' => $this->name_en,
            'description' => $this->description,
            'description_en' => $this->description_en,

            'order_index' => (int) ($this->order_index ?? 0),
            'required_stars' => (int) ($this->required_stars ?? 0),

            'total_stages' => (int) $totalStages,
            'completed_stages' => (int) $completedStages,
            'completion_percentage' => $totalStages > 0
                ? (int) round(($completedStages / $totalStages) * 100)
                : 0,

            'total_stars' => (int) ($this->studentProgress->total_stars ?? 0),
            'is_completed' => (bool) ($this->studentProgress->is_completed ?? false),
            'is_unlocked' => (bool) ($this->studentProgress->is_unlocked ?? false),
            'is_premium' => $isPremium,
            'is_locked_by_subscription' => $isLockedBySub,
        ];
    }
}
