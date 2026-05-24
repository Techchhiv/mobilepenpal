<?php

namespace App\Http\Controllers\Admin\V01;

use App\Http\Requests\Admin\UpdateSystemSettingRequest;
use App\Models\SystemSetting;
use Illuminate\Http\JsonResponse;

class SystemSettingController extends Controller
{
    public function show(string $key): JsonResponse
    {
        $setting = SystemSetting::find($key);

        $value = $setting
            ? $setting->value
            : [];

        return $this->returnSuccess('OK', [
            'key' => $key,
            'settings' => $value,
        ]);
    }

    public function update(UpdateSystemSettingRequest $request, string $key): JsonResponse
    {
        $setting = SystemSetting::updateOrCreate(
            ['key' => $key],
            ['value' => $request->input('value')],
        );

        return $this->returnSuccess('Settings updated successfully', [
            'key' => $setting->key,
            'settings' => $setting->value,
        ]);
    }
}

