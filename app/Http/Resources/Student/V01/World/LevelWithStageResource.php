<?php

namespace App\Http\Resources\Student\V01\World;

use Illuminate\Http\Resources\Json\JsonResource;

class LevelWithStageResource extends JsonResource
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

            'world_name' => $this->world?->name,
            'world_name_en' => $this->world?->name_en,

            'stages' => StageWithProgressResource::collection($this->stages),
        ];
    }
}
