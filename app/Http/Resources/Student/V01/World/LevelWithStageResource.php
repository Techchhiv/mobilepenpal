<?php

namespace App\Http\Resources\Student\V01\World;

use Illuminate\Http\Resources\Json\JsonResource;

class LevelWithStageResource extends JsonResource
{
    public function toArray($request)
    {
        $isPremium = (bool) $this->is_premium;
        $isLockedBySub = (bool) $this->isLockedBySubscriptionForUser();

        return [
            'id' => (int) $this->id,

            'name' => $this->name,
            'name_en' => $this->name_en,
            'description' => $this->description,
            'description_en' => $this->description_en,

            'order_index' => (int) ($this->order_index ?? 0),

            'world_name' => $this->world?->name,
            'world_name_en' => $this->world?->name_en,

            'is_premium' => $isPremium,
            'is_locked_by_subscription' => $isLockedBySub,

            'stages' => StageWithProgressResource::collection($this->stages),
        ];
    }
}
