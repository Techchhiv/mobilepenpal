<?php

namespace App\Http\Resources\Student\V01\World;

use Illuminate\Http\Resources\Json\JsonResource;

class WorldIndexResource extends JsonResource
{
    public function toArray($request)
    {
        $isUnlocked = false;

        if ($this->is_unlocked_by_default) {
            $isUnlocked = true;
        } elseif ($this->studentProgress) {
            $isUnlocked = (bool) $this->studentProgress->is_unlocked;
        }

        $levelsTotal = (int) ($this->levels_count ?? 0);
        $levelsCompleted = (int) ($this->completed_levels_count ?? 0);

        return [
            'id' => (int) $this->id,

            'name' => $this->name,
            'name_en' => $this->name_en,
            'description' => $this->description,
            'description_en' => $this->description_en,

            'is_unlocked' => $isUnlocked,
            'is_completed' => $this->studentProgress ? (bool) $this->studentProgress->is_completed : false,

            'levels_completed' => $levelsCompleted,
            'levels_total' => $levelsTotal,
            'levels_remaining' => max(0, $levelsTotal - $levelsCompleted),
        ];
    }
}
