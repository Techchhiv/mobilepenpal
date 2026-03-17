<?php

namespace App\Http\Resources\Student\V01\World;

use Illuminate\Http\Resources\Json\JsonResource;

class AdventureExerciseResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'id' => (int) $this->id,

            'prompt' => $this->prompt,
            'character' => $this->character,
            'example' => $this->example,

            'question' => $this->question,
            'options' => $this->options,
            'instruction' => $this->instruction,
            'hint' => $this->hint,

            'character_type' => $this->character_type,
            'difficulty' => $this->difficulty,
            'math_op' => $this->math_op,
        ];
    }
}
