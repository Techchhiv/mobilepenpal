<?php

namespace App\Http\Resources\Student\V01\World;

use Illuminate\Http\Resources\Json\JsonResource;

class ExerciseResource extends JsonResource
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

            'prompt' => $this->prompt,
            'character' => $this->character,

            'question' => $this->question,
            'options' => $this->options,
            'instruction' => $this->instruction,
            'hint' => $this->hint,

            'order_index' => $this->order_index,
            'audio_url' => $this->audio_url,
            'image_url' => $this->image_url,
        ];
    }
}
