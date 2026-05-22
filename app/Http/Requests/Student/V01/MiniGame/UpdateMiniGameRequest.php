<?php

namespace App\Http\Requests\Student\V01\MiniGame;

use App\Helpers\UploadMedia;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\ValidationException;
use Illuminate\Support\Facades\Storage;

class UpdateMiniGameRequest extends FormRequest
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
            'title' => 'sometimes|required|string|max:255',
            'title_kh' => 'sometimes|nullable|string|max:255',
            'description' => 'sometimes|nullable|string',
            'description_kh' => 'sometimes|nullable|string',
            'display_type' => 'sometimes|required|string|max:255',
            'input_type' => 'sometimes|required|string|max:255',
            'is_active' => 'sometimes|boolean',
            'cover_image_url' => 'sometimes|nullable|string|max:2048',
            'cover_image_base64' => 'sometimes|nullable|string',
            'cover_image' => 'sometimes|nullable|string',
            'config' => 'sometimes|nullable|array',
        ];
    }

    public function data(?string $currentCoverImageUrl = null): array
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

            $this->deleteOldCoverImage($currentCoverImageUrl);

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

            $this->deleteOldCoverImage($currentCoverImageUrl);
        }

        return $validated;
    }

    private function deleteOldCoverImage(?string $currentCoverImageUrl): void
    {
        if (!$currentCoverImageUrl) {
            return;
        }

        if (str_starts_with($currentCoverImageUrl, 'http://') || str_starts_with($currentCoverImageUrl, 'https://')) {
            return;
        }

        $path = ltrim($currentCoverImageUrl, '/');

        if (!str_starts_with($path, 'images/uploads/')) {
            return;
        }

        if (Storage::disk('uploads')->exists($path)) {
            Storage::disk('uploads')->delete($path);
        }
    }
}