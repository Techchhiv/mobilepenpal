<?php

namespace App\Http\Resources\Student\V01\World;

use Illuminate\Http\Resources\Json\JsonResource;

class WorldIndexResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return array|\Illuminate\Contracts\Support\Arrayable|\JsonSerializable
     */
    public function toArray($request)
    {
        $isUnlocked = false;

        if ($this->is_unlocked_by_default) {
            $isUnlocked = true;
        } elseif ($this->studentProgress) {
            $isUnlocked = (bool) $this->studentProgress->is_unlocked;
        }

        return [
            'id' => $this->id,
            'name' => $this->name,
            'description' => $this->description,
            'icon_url' => $this->icon_url,
            'map_image_url' => $this->map_image_url,
            'theme_color' => $this->theme_color,
            'is_unlocked' => $isUnlocked,
            'is_completed' => $this->studentProgress ? (bool) $this->studentProgress->is_completed : false,
            'levels_completed' => $this->completed_levels_count ?? 0,
            'levels_total' => $this->levels_count,
            'levels_remaining' => $this->levels_count - ($this->completed_levels_count ?? 0),
        ];
    }
}
