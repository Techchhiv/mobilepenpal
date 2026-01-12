<?php

namespace App\Http\Resources\Student\V01\Classroom;

use Illuminate\Http\Resources\Json\JsonResource;

class ClassroomResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'is_active' => (bool) $this->is_active,

            'students_count' => $this->students_count ?? 0,

            'teacher' => $this->whenLoaded('teacher', function () {
                return [
                    'id' => $this->teacher->id,
                    'name' => $this->teacher->name,
                ];
            }),


            'enrollment' => $this->when($this->relationLoaded('enrollment'), function () {
                return [
                    'status' => $this->enrollment->status,
                    'enrolled_at' => $this->enrollment->enrolled_at?->toDateTimeString(),
                    'left_at' => $this->enrollment->left_at?->toDateTimeString(),
                ];
            }),
        ];
    }
}
