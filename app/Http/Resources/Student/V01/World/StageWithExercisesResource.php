<?php

namespace App\Http\Resources\Student\V01\World;

use Illuminate\Http\Resources\Json\JsonResource;

class StageWithExercisesResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return array|\Illuminate\Contracts\Support\Arrayable|\JsonSerializable
     */
    public function toArray($request)
    {
        $exercises = $this->exercises
            ->sortBy(fn($exercise) => $exercise->pivot->order_index);

        $expandedExercises = $exercises
            ->sortBy('order_index')
            ->flatMap(function ($exercise) {
                $times = $exercise->pivot->repeat_count ?? 1;

                return collect(range(1, $times))->map(function ($slotIndex) use ($exercise) {
                    $clone = $exercise->replicate();
                    $clone->id = $exercise->id;
                    $clone->repeat_slot = $slotIndex;

                    return $clone;
                });
            })
            ->values();

        return [
            'id' => $this->id,
            'name' => $this->name,
            'instruction' => $this->instruction,
            'description' => $this->description,
            'order_index' => $this->order_index,
            'max_stars' => $this->max_stars,
            'exercises' => ExerciseResource::collection($expandedExercises),
        ];
    }
}
