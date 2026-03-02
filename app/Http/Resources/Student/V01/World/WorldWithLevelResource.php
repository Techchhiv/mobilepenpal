<?php

namespace App\Http\Resources\Student\V01\World;

use Illuminate\Http\Resources\Json\JsonResource;

class WorldWithLevelResource extends JsonResource
{
    public function toArray($request)
    {
        $isPremium = (bool) $this->is_premium;
        $hasSubscription = auth()->user()?->hasActiveSubscription() ?? false;

        return [
            'id' => (int) $this->id,

            'name' => $this->name,
            'name_en' => $this->name_en,
            'description' => $this->description,
            'description_en' => $this->description_en,

            'is_premium' => $isPremium,
            'is_locked_by_subscription' => $isPremium && !$hasSubscription,

            'levels' => LevelWithProgressResource::collection($this->levels),
        ];
    }
}
