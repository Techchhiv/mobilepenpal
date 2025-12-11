<?php

namespace App\Http\Resources\Student\V01\World;

use Illuminate\Http\Resources\Json\JsonResource;

class StageWithProgressResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return array|\Illuminate\Contracts\Support\Arrayable|\JsonSerializable
     */
    public function toArray($request)
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'instruction' => $this->instruction,
            'description' => $this->description,
            'order_index' => $this->order_index,
            'max_stars' => $this->max_stars,
            'stars_earned' => $this->studentProgress ? $this->studentProgress->stars_earned : 0,
            'status' => $this->studentProgress ? $this->studentProgress->status : 'locked',
        ];
    }
}
