<?php

namespace App\Http\Resources\Student\V01\World;

use Illuminate\Http\Resources\Json\JsonResource;

class WorldWithLevelResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'id' => (int) $this->id,

            'name' => $this->name,
            'name_en' => $this->name_en,
            'description' => $this->description,
            'description_en' => $this->description_en,

            'levels' => LevelWithProgressResource::collection($this->levels),
        ];
    }
}
