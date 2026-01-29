<?php

namespace App\Http\Resources\Student\V01\User;

use Illuminate\Http\Resources\Json\JsonResource;

class UserDetailResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return array|\Illuminate\Contracts\Support\Arrayable|\JsonSerializable
     */
    public function toArray($request)
    {
        return collect(parent::toArray($request))->except([
            // 'school_id',
            // 'school_key',
            // 'enrollment_year',
            'is_active',
            'created_at',
            'updated_at',
        ]);
    }
}
