<?php

namespace App\Http\Requests\Student\V01\MiniGame;

use App\Helpers\UploadMedia;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\ValidationException;

class StoreMiniGameRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        if ($this->has('config') && is_string($this->input('config'))) {
            $decoded = json_decode($this->input('config'), true);

            if (json_last_error() === JSON_ERROR_NONE) {
                $this->merge([
                    'config' => $decoded,
                ]);
            }
        }

        if ($this->has('cover_image') && !$this->has('cover_image_base64')) {
            $this->merge([
                'cover_image_base64' => $this->input('cover_image'),
            ]);
        }
    }

    public function rules(): array
    {
        return [
            'title' => 'required|string|max:255',
            'title_kh' => 'nullable|string|max:255',
            'description' => 'nullable|string',
            'description_kh' => 'nullable|string',
            'display_type' => 'required|string|max:255',
            'input_type' => 'required|string|max:255',
            'is_active' => 'sometimes|boolean',
            'cover_image_url' => 'nullable|string|max:2048',
            'cover_image_base64' => 'nullable|string',
            'cover_image' => 'nullable|string',
            'config' => 'nullable|array',
        ];
    }

    public function data(): array
    {
        $validated = $this->validated();

        $base64Image = $validated['cover_image_base64'] ?? null;
        $imageFile = $this->file('cover_image_file');

        unset(
            $validated['cover_image_base64'],
            $validated['cover_image'],
            $validated['cover_image_file']
        );

        if ($imageFile) {
            $imagePath = UploadMedia::uploadImageFile($imageFile);

            if (!$imagePath) {
                throw ValidationException::withMessages([
                    'cover_image_file' => 'Invalid image. Only png, jpg, and jpeg are allowed.',
                ]);
            }

            $validated['cover_image_url'] = $imagePath;

            return $validated;
        }

        if ($base64Image) {
            $imagePath = UploadMedia::uploadImageBase64($base64Image);

            if (!$imagePath) {
                throw ValidationException::withMessages([
                    'cover_image_base64' => 'Invalid base64 image. Only png, jpg, and jpeg are allowed.',
                ]);
            }

            $validated['cover_image_url'] = $imagePath;
        }

        return $validated;
    }
}