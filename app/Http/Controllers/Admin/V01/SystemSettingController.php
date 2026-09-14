<?php

namespace App\Http\Controllers\Admin\V01;

use App\Http\Requests\Admin\UpdateSystemSettingRequest;
use App\Models\SystemSetting;
use App\Services\AuditService;
use Illuminate\Http\JsonResponse;

class SystemSettingController extends Controller
{
    public function show(string $key): JsonResponse
    {
        if ($key === 'subscription') {
            $value = app(\App\Services\SubscriptionBillingService::class)->getSubscriptionSettings();
        } else {
            $setting = SystemSetting::find($key);
            $value = $setting ? $setting->value : [];
        }

        return $this->returnSuccess('OK', [
            'key' => $key,
            'settings' => $value,
        ]);
    }

    public function update(UpdateSystemSettingRequest $request, string $key): JsonResponse
    {
        $existing = SystemSetting::find($key);
        $oldValue = $existing ? $existing->value : null;
        $payload = $request->input('value');

        if ($key === 'subscription' && is_array($payload)) {
            if (isset($payload['monthly_price'])) {
                $payload['price'] = $payload['monthly_price'];
            } elseif (isset($payload['price'])) {
                $payload['monthly_price'] = $payload['price'];
            }

            if (isset($payload['monthly_discount'])) {
                $payload['discount'] = $payload['monthly_discount'];
            } elseif (isset($payload['discount'])) {
                $payload['monthly_discount'] = $payload['discount'];
            }
        }

        $setting = SystemSetting::updateOrCreate(
            ['key' => $key],
            ['value' => $payload],
        );

        AuditService::record(
            action: 'system.setting.updated',
            target: $setting,
            old: ['key' => $key, 'value' => $oldValue],
            new: ['key' => $key, 'value' => $request->input('value')],
            description: "System setting updated: {$key}",
            severity: 'warning'
        );

        return $this->returnSuccess('Settings updated successfully', [
            'key'      => $setting->key,
            'settings' => $setting->value,
        ]);
    }

    public function showFeatureLocks(): JsonResponse
    {
        return $this->show('feature_locks');
    }

    public function updateFeatureLocks(UpdateSystemSettingRequest $request): JsonResponse
    {
        return $this->update($request, 'feature_locks');
    }
}

