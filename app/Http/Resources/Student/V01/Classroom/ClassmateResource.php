<?php

namespace App\Http\Resources\Student\V01\Classroom;

use Illuminate\Http\Resources\Json\JsonResource;

class ClassmateResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'id'         => $this->id,
            'first_name' => $this->first_name,
            'last_name'  => $this->last_name,
            'nickname'   => $this->nickname,
            'avatar'     => $this->avatar,
        ];
    }
}
