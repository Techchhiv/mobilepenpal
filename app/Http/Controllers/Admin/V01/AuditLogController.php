<?php

namespace App\Http\Controllers\Admin\V01;

use App\Models\AuditLog;
use App\Services\AuditService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Carbon\Carbon;

class AuditLogController extends Controller
{
    /**
     * GET /api/admin/audit-logs
     * Paginated, filtered list of audit log entries.
     */
    public function index(Request $request): JsonResponse
    {
        $query = AuditLog::query()->orderByDesc('occurred_at');

        // ── Full-text / keyword search ──
        if ($search = $request->input('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('actor_name', 'like', "%{$search}%")
                    ->orWhere('actor_email', 'like', "%{$search}%")
                    ->orWhere('description', 'like', "%{$search}%")
                    ->orWhere('action', 'like', "%{$search}%");
            });
        }

        // ── Category filter ──
        if ($category = $request->input('category')) {
            $query->where('category', $category);
        }

        // ── Action filter ──
        if ($action = $request->input('action')) {
            $query->where('action', 'like', "%{$action}%");
        }

        // ── Severity filter ──
        if ($severity = $request->input('severity')) {
            $query->where('severity', $severity);
        }

        // ── Actor filter (by email) ──
        if ($actor = $request->input('actor')) {
            $query->where(function ($q) use ($actor) {
                $q->where('actor_email', 'like', "%{$actor}%")
                    ->orWhere('actor_name', 'like', "%{$actor}%");
            });
        }

        // ── School filter ──
        if ($schoolId = $request->input('school_id')) {
            $query->where('school_id', $schoolId);
        }

        // ── Target type filter ──
        if ($targetType = $request->input('target_type')) {
            $query->where('target_type', 'like', "%{$targetType}%");
        }

        // ── Date range filters ──
        if ($dateFrom = $request->input('date_from')) {
            $query->where('occurred_at', '>=', Carbon::parse($dateFrom)->startOfDay());
        }
        if ($dateTo = $request->input('date_to')) {
            $query->where('occurred_at', '<=', Carbon::parse($dateTo)->endOfDay());
        }

        $perPage = min((int) $request->input('per_page', 20), 100);
        $logs    = $query->paginate($perPage);

        return response()->json([
            'code'    => 200,
            'message' => 'OK',
            'data'    => $logs,
            'errors'  => [],
        ]);
    }

    /**
     * GET /api/admin/audit-logs/{id}
     * Single audit log detail.
     */
    public function show(int $id): JsonResponse
    {
        $log = AuditLog::find($id);

        if (!$log) {
            return response()->json([
                'code'    => 404,
                'message' => 'Audit log not found.',
                'data'    => null,
                'errors'  => [],
            ], 404);
        }

        return response()->json([
            'code'    => 200,
            'message' => 'OK',
            'data'    => $log,
            'errors'  => [],
        ]);
    }

    /**
     * GET /api/admin/audit-logs/export
     * Stream a CSV file of filtered audit records.
     */
    public function export(Request $request)
    {
        // ── Build same filtered query (no pagination) ──
        $query = AuditLog::query()->orderByDesc('occurred_at');

        if ($search = $request->input('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('actor_name', 'like', "%{$search}%")
                    ->orWhere('actor_email', 'like', "%{$search}%")
                    ->orWhere('description', 'like', "%{$search}%")
                    ->orWhere('action', 'like', "%{$search}%");
            });
        }
        if ($category = $request->input('category'))    $query->where('category', $category);
        if ($action   = $request->input('action'))      $query->where('action', 'like', "%{$action}%");
        if ($severity = $request->input('severity'))    $query->where('severity', $severity);
        if ($actor    = $request->input('actor')) {
            $query->where(fn($q) => $q->where('actor_email', 'like', "%{$actor}%")->orWhere('actor_name', 'like', "%{$actor}%"));
        }
        if ($schoolId  = $request->input('school_id')) $query->where('school_id', $schoolId);
        if ($dateFrom  = $request->input('date_from'))  $query->where('occurred_at', '>=', Carbon::parse($dateFrom)->startOfDay());
        if ($dateTo    = $request->input('date_to'))    $query->where('occurred_at', '<=', Carbon::parse($dateTo)->endOfDay());

        // Limit export to 10,000 rows to prevent memory issues
        $logs = $query->limit(10000)->get();

        // ── Record the export event itself ──
        AuditService::record(
            action: 'audit.exported',
            description: 'Super Admin exported audit logs to CSV (' . $logs->count() . ' records)',
            severity: 'warning',
            metadata: ['filters' => $request->only(['search', 'category', 'action', 'severity', 'actor', 'school_id', 'date_from', 'date_to'])]
        );

        // ── Stream CSV ──
        $filename  = 'audit_logs_' . now()->format('Y-m-d_His') . '.csv';
        $headers   = [
            'Content-Type'        => 'text/csv',
            'Content-Disposition' => "attachment; filename=\"{$filename}\"",
        ];

        $csvHeaders = [
            'ID', 'Event UUID', 'Occurred At', 'Category', 'Action', 'Severity',
            'Actor Name', 'Actor Email', 'Actor Roles',
            'School ID', 'Target Type', 'Target ID',
            'Description', 'IP Address', 'HTTP Method', 'Route', 'Source',
        ];

        $callback = function () use ($logs, $csvHeaders) {
            $handle = fopen('php://output', 'w');
            fputcsv($handle, $csvHeaders);

            foreach ($logs as $log) {
                fputcsv($handle, [
                    $log->id,
                    $log->event_uuid,
                    $log->occurred_at?->toDateTimeString(),
                    $log->category,
                    $log->action,
                    $log->severity,
                    $log->actor_name,
                    $log->actor_email,
                    implode(', ', $log->actor_roles ?? []),
                    $log->school_id,
                    $log->target_type,
                    $log->target_id,
                    $log->description,
                    $log->ip_address,
                    $log->http_method,
                    $log->route,
                    $log->source,
                ]);
            }

            fclose($handle);
        };

        return response()->stream($callback, 200, $headers);
    }
}
