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
            'is_active'      => (bool) $this->is_active,
            'students_count' => $this->students_count ?? null,

            'teacher' => $this->whenLoaded('teacher', function () {
                return [
                    'id'   => $this->teacher->id,
                    'name' => $this->teacher->name,
                ];
            }),

            // set in controller: $classroom->setRelation('enrollment', $enrollment)
            'enrollment' => $this->whenLoaded('enrollment', function () {
                return new EnrollmentResource($this->enrollment);
            }),

            // set in controller: $classroom->setRelation('classmates', $students)
            'classmates' => $this->whenLoaded('classmates', function () {
                return ClassmateResource::collection($this->classmates);
            }),
        ];
    }
}
