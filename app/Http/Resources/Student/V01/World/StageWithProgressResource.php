<?php

namespace App\Http\Resources\Student\V01\World;

use Illuminate\Http\Resources\Json\JsonResource;

class StageWithProgressResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'id' => (int) $this->id,

            'name' => $this->name,
            'name_en' => $this->name_en,
            'description' => $this->description,
            'description_en' => $this->description_en,

            'order_index' => (int) ($this->order_index ?? 0),
            'max_stars' => (int) ($this->max_stars ?? 0),

            'stars_earned' => (int) ($this->studentProgress?->stars_earned ?? 0),
            'status' => (string) ($this->studentProgress?->status ?? 'locked'),
        ];
    }
}
