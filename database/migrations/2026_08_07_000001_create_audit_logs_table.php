<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('audit_logs', function (Blueprint $table) {
            // Primary key
            $table->id();

            // Unique event identifier
            $table->uuid('event_uuid')->unique();

            // When the event happened (indexed for range queries)
            $table->timestamp('occurred_at')->useCurrent()->index();

            // Event classification
            $table->string('category', 100)->index();
            $table->string('action', 150)->index();
            $table->enum('severity', ['info', 'warning', 'critical'])->default('info')->index();

            // Actor (who performed the action) — snapshotted so records survive user deletion
            $table->unsignedBigInteger('actor_id')->nullable()->index();
            $table->string('actor_type', 100)->nullable();
            $table->string('actor_name', 255)->nullable();
            $table->string('actor_email', 255)->nullable()->index();
            $table->json('actor_roles')->nullable();

            // School scope
            $table->unsignedBigInteger('school_id')->nullable()->index();

            // Target entity (what was affected)
            $table->string('target_type', 150)->nullable()->index();
            $table->unsignedBigInteger('target_id')->nullable()->index();

            // Human-readable description
            $table->text('description')->nullable();

            // Before / after values (sensitive fields always redacted)
            $table->json('old_values')->nullable();
            $table->json('new_values')->nullable();

            // Request context
            $table->string('ip_address', 45)->nullable();
            $table->string('user_agent', 500)->nullable();
            $table->string('source', 50)->default('web');
            $table->string('request_id', 100)->nullable();
            $table->string('http_method', 10)->nullable();
            $table->string('route', 300)->nullable();

            // Extra structured metadata (entity snapshots on delete, etc.)
            $table->json('metadata')->nullable();

            // Only created_at — audit records are NEVER updated
            $table->timestamp('created_at')->useCurrent();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('audit_logs');
    }
};
