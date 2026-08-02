<?php

namespace App\Http\Resources\Student\V01\Classroom;

use Illuminate\Http\Resources\Json\JsonResource;

class ClassroomDetailResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'id'             => $this->id,
            'name'           => $this->name,
            'join_code'      => $this->join_code ?? null,
            'is_active'      => (bool) $this->is_active,
            'students_count' => $this->students_count ?? null,
            'my_stats'       => $this->my_stats ?? null,

            'teacher' => $this->whenLoaded('teacher', function () {
                return [
                    'id'   => $this->teacher->id,
                    'name' => $this->teacher->name,
                ];
            }),

            'enrollment' => $this->whenLoaded('enrollment', function () {
                return new EnrollmentResource($this->enrollment);
            }),

            'classmates' => $this->whenLoaded('classmates', function () {
                return ClassmateResource::collection($this->classmates);
            }),
        ];
    }
}
