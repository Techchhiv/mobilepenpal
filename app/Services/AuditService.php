<?php

namespace App\Services;

use App\Models\AuditLog;
use Illuminate\Support\Facades\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Str;
use Throwable;

class AuditService
{
    // Sensitive field keys that must NEVER appear in old_values / new_values
    protected static array $sensitiveKeys = [
        'password',
        'password_confirmation',
        'current_password',
        'new_password',
        'token',
        'access_token',
        'refresh_token',
        'authorization',
        'remember_token',
        'otp',
        'secret',
        'api_key',
        'api_secret',
        'private_key',
        'school_key', // school authentication keys
    ];

    /**
     * Record an audit event.
     *
     * @param  string       $action       e.g. "auth.login.success"
     * @param  object|null  $target       Eloquent model that was acted upon
     * @param  array|null   $old          Previous values (will be sanitized)
     * @param  array|null   $new          New values (will be sanitized)
     * @param  string|null  $description  Human-readable summary
     * @param  string       $severity     "info" | "warning" | "critical"
     * @param  array        $metadata     Extra JSON metadata (e.g. deletion snapshot)
     */
    public static function record(
        string $action,
        ?object $target = null,
        ?array $old = null,
        ?array $new = null,
        ?string $description = null,
        string $severity = 'info',
        array $metadata = []
    ): ?AuditLog {
        try {
            // ── Resolve category from action string ──
            $parts = explode('.', $action);
            $category = $parts[0] ?? 'general';

            // ── Resolve authenticated actor ──
            $actor = null;
            try {
                $actor = Auth::guard('api')->user() ?? Auth::user();
            } catch (Throwable) {
                // No auth context available (CLI / system-generated events)
            }

            $actorId    = $actor?->id;
            $actorType  = $actor ? get_class($actor) : null;
            $actorName  = $actor?->name;
            $actorEmail = $actor?->email;
            $actorRoles = $actor?->roles?->pluck('name')->toArray() ?? [];
            $schoolId   = $actor?->school_id ?? null;

            // ── Resolve target ──
            $targetType = null;
            $targetId   = null;
            if ($target !== null) {
                $targetType = get_class($target);
                $targetId   = $target->getKey() ?? null;

                // Inherit school_id from target when actor has none
                if ($schoolId === null && isset($target->school_id)) {
                    $schoolId = $target->school_id;
                }
            }

            // ── Sanitize old/new values ──
            $oldSanitized = $old !== null ? self::sanitize($old) : null;
            $newSanitized = $new !== null ? self::sanitize($new) : null;

            // ── Request context ──
            $request    = Request::instance();
            $ipAddress  = $request->ip();
            $userAgent  = substr($request->userAgent() ?? '', 0, 500);
            $httpMethod = $request->method();
            $route      = $request->path();
            $requestId  = $request->header('X-Request-Id') ?? Str::uuid()->toString();

            // ── Source detection ──
            $source = 'web';
            if (app()->runningInConsole()) {
                $source = 'cli';
            } elseif (str_contains($userAgent, 'Dart') || str_contains($userAgent, 'Flutter')) {
                $source = 'mobile';
            }

            return AuditLog::create([
                'event_uuid'  => Str::uuid()->toString(),
                'occurred_at' => now(),
                'category'    => $category,
                'action'      => $action,
                'severity'    => $severity,
                'actor_id'    => $actorId,
                'actor_type'  => $actorType,
                'actor_name'  => $actorName,
                'actor_email' => $actorEmail,
                'actor_roles' => $actorRoles ?: null,
                'school_id'   => $schoolId,
                'target_type' => $targetType,
                'target_id'   => $targetId,
                'description' => $description,
                'old_values'  => $oldSanitized,
                'new_values'  => $newSanitized,
                'ip_address'  => $ipAddress,
                'user_agent'  => $userAgent,
                'source'      => $source,
                'request_id'  => $requestId,
                'http_method' => $httpMethod,
                'route'       => '/' . ltrim($route, '/'),
                'metadata'    => $metadata ?: null,
            ]);
        } catch (Throwable $e) {
            // Audit logging must NEVER break the main application flow
            \Illuminate\Support\Facades\Log::error('AuditService::record failed', [
                'action'    => $action,
                'error'     => $e->getMessage(),
            ]);
            return null;
        }
    }

    /**
     * Record an event without any authenticated user (system/CLI context).
     */
    public static function system(
        string $action,
        ?object $target = null,
        ?array $old = null,
        ?array $new = null,
        ?string $description = null,
        string $severity = 'info',
        array $metadata = []
    ): ?AuditLog {
        return self::record($action, $target, $old, $new, $description, $severity, array_merge($metadata, ['actor_context' => 'system']));
    }

    /**
     * Build a diff array from two arrays, returning only changed keys.
     * Use this to avoid dumping entire models in old/new values.
     */
    public static function diff(array $before, array $after): array
    {
        $changed = [];
        foreach ($after as $key => $newVal) {
            $oldVal = $before[$key] ?? null;
            if ($oldVal != $newVal) {
                $changed[$key] = true;
            }
        }
        return array_intersect_key($before, $changed);
    }

    /**
     * Recursively remove all sensitive keys from an array before persisting.
     */
    public static function sanitize(array $data): array
    {
        $result = [];
        foreach ($data as $key => $value) {
            if (in_array(strtolower((string) $key), self::$sensitiveKeys, true)) {
                // Replace the value with a safe indicator
                $result[$key] = '[REDACTED]';
            } elseif (is_array($value)) {
                $result[$key] = self::sanitize($value);
            } else {
                $result[$key] = $value;
            }
        }
        return $result;
    }
}
