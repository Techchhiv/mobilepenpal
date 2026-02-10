<?php

namespace App\Http\Resources\Student\V01\World;

use Illuminate\Http\Resources\Json\JsonResource;

class StageWithExercisesResource extends JsonResource
{
    public function toArray($request)
    {
        $exercises = $this->exercises
            ->sortBy(fn($exercise) => $exercise->pivot->order_index);

        $expandedExercises = $exercises
            ->flatMap(function ($exercise) {
                $times = (int) ($exercise->pivot->repeat_count ?? 1);

                return collect(range(1, max(1, $times)))->map(function ($slotIndex) use ($exercise) {
                    $clone = $exercise->replicate();
                    $clone->id = $exercise->id;
                    $clone->repeat_slot = $slotIndex;
                    $clone->setRelation('pivot', $exercise->pivot);
                    return $clone;
                });
            })
            ->values();

        return [
            'id' => (int) $this->id,

            'name' => $this->name,
            'name_en' => $this->name_en,
            'description' => $this->description,
            'description_en' => $this->description_en,

            'order_index' => (int) ($this->order_index ?? 0),
            'max_stars' => (int) ($this->max_stars ?? 0),

            'exercises' => ExerciseResource::collection($expandedExercises),
        ];
    }
}
