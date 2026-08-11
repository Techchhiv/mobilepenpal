<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class AuditLog extends Model
{
    use HasFactory;

    // No updated_at — audit records are never updated
    const UPDATED_AT = null;

    protected $table = 'audit_logs';

    // All columns are mass-assignable via AuditService only; no public API writes allowed.
    protected $guarded = [];

    protected $casts = [
        'occurred_at' => 'datetime',
        'actor_roles'  => 'array',
        'old_values'   => 'array',
        'new_values'   => 'array',
        'metadata'     => 'array',
        'created_at'   => 'datetime',
    ];

    // ──────────────────────────────────────────────────────────
    // Immutability guards — throw if app code tries to update/delete
    // ──────────────────────────────────────────────────────────

    protected static function booted(): void
    {
        static::updating(function () {
            throw new \RuntimeException('AuditLog records are immutable and cannot be updated.');
        });

        static::deleting(function () {
            throw new \RuntimeException('AuditLog records are immutable and cannot be deleted.');
        });
    }
}
