<?php

namespace App\Helpers;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class UploadMedia
{
    public static function uploadImageBase64(?string $base64)
    {
        if (!$base64) {
            return false;
        }

        if (preg_match('/^data:image\/(\w+);base64,/', $base64, $matches)) {
            $extension = strtolower($matches[1]);
            $base64 = substr($base64, strpos($base64, ',') + 1);
        } else {
            $extension = 'png';
        }

        $allowed = ['png', 'jpg', 'jpeg'];

        if (!in_array($extension, $allowed)) {
            return false;
        }

        $imageData = base64_decode($base64);

        if (!$imageData) {
            return false;
        }

        $folder = self::imageUploadFolder();
        $fileName = Str::uuid() . '_' . time() . '.' . $extension;
        $path = $folder . $fileName;

        Storage::disk('uploads')->put($path, $imageData);

        return '/' . $path;
    }

    public static function uploadImageFile(UploadedFile $file)
    {
        $extension = strtolower($file->getClientOriginalExtension());

        $allowed = ['png', 'jpg', 'jpeg'];

        if (!in_array($extension, $allowed)) {
            return false;
        }

        $folder = self::imageUploadFolder();
        $fileName = Str::uuid() . '_' . time() . '.' . $extension;

        Storage::disk('uploads')->putFileAs($folder, $file, $fileName);

        return '/' . $folder . $fileName;
    }

    private static function imageUploadFolder(): string
    {
        $year = date('Y');
        $month = date('m');
        $day = date('d');

        return "images/uploads/$year/$month/$day/";
    }
}