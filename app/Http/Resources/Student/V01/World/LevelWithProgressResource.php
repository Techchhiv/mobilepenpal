<?php

namespace App\Http\Resources\Student\V01\World;

use Illuminate\Http\Resources\Json\JsonResource;

class LevelWithProgressResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return array|\Illuminate\Contracts\Support\Arrayable|\JsonSerializable
     */
    public function toArray($request)
    {
        $totalStages = $this->stages->count();
        $completedStages = $this->completedStagesProgress->count();

        return [
            'id' => $this->id,
            'name' => $this->name,
            'description' => $this->description,
            'order_index' => $this->order_index,
            'background_image' => $this->background_image,
            'required_stars' => $this->required_stars,
            'total_stages' => $totalStages,
            'completed_stages' => $completedStages,
            'completion_percentage' => $totalStages > 0 ? round(($completedStages / $totalStages) * 100) : 0,
            'total_stars' => $this->studentProgress->total_stars ?? 0,
            'is_completed' => $this->studentProgress->is_completed ?? false,
            'is_unlocked' => $this->studentProgress->is_unlocked ?? false,
        ];
    }
}
