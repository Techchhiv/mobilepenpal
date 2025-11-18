<?php



namespace App\Helpers;

use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

function uploadImageBase64($base64)
{
    $allowed = ['png', 'jpg', 'jpeg'];

    if (!str_starts_with($base64, 'data:image')) {
        return false;
    }

    preg_match('/data:image\/(.*?);base64/', $base64, $match);

    if (!isset($match[1]) || !in_array($match[1], $allowed)) {
        return false;
    }

    $fileExtention = strtolower($match[1]);
    $base64 = explode(',', $base64)[1];
    $imageData = base64_decode($base64);

    if (!$imageData) {
        return false;
    }

    $year  = date("Y");
    $month = date("m");
    $day   = date("d");

    $folder = "images/uploads/$year/$month/$day/";

    $imageFileName = Str::uuid() . '_' . time() . '.' . $fileExtention;

    Storage::disk('uploads')->put($folder . $imageFileName, $imageData);

    return '/' . $folder . $imageFileName;
}
