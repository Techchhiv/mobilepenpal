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
        $data = collect(parent::toArray($request))->except([
            // 'school_id',
            // 'school_key',
            // 'enrollment_year',
            'is_active',
            'created_at',
            'updated_at',
        ]);

        $activeSubscription = $this->resource->getActiveSubscription();

        $data['has_subscription'] = $activeSubscription !== null;
        $data['subscription_plan'] = $activeSubscription ? $activeSubscription->plan : null;
        $data['subscription_start_date'] = $activeSubscription ? $activeSubscription->start_date : null;
        $data['subscription_end_date'] = $activeSubscription ? $activeSubscription->end_date : null;

        return $data;
    }
}
