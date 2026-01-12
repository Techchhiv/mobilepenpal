<?php

namespace App\Http\Resources\Student\V01\Classroom;

use Illuminate\Http\Resources\Json\JsonResource;

class EnrollmentResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'status'      => $this->status,
            'enrolled_at' => $this->enrolled_at,
            'left_at'     => $this->left_at,
        ];
    }
}
