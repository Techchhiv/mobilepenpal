<?php

namespace App\Http\Requests\Admin\World;

use App\Models\World;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Validator;

class ReorderWorldRequest extends FormRequest
{

    public function rules(): array
    {
        return [
            'world_ids'   => ['required', 'array', 'min:1'],
            'world_ids.*' => ['integer'],
        ];
    }

    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $v) {
            $ids = $this->input('world_ids', []);
            if (!is_array($ids) || empty($ids)) {
                return;
            }

            if (count($ids) !== count(array_unique($ids))) {
                $v->errors()->add('world_ids', 'world_ids contains duplicates.');
                return;
            }

            $count = World::whereIn('id', $ids)->count();
            if ($count !== count($ids)) {
                $v->errors()->add('world_ids', 'One or more world_ids are invalid.');
            }
        });
    }

    public function ids(): array
    {
        return array_values($this->input('world_ids', []));
    }
}
