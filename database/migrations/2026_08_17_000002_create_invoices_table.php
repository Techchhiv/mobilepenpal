<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('invoices', function (Blueprint $table) {
            $table->id();

            // Human-readable sequential invoice number e.g. INV-2026-000001
            $table->string('invoice_number', 30)->unique();

            // Linked subscription — nullable so the invoice record survives if subscription is ever soft-deleted/nulled
            $table->foreignId('subscription_id')->nullable()->constrained('subscriptions')->nullOnDelete();

            // Customer snapshot — who was billed (at the time of billing)
            $table->enum('customer_type', ['school', 'student']);
            $table->unsignedBigInteger('school_id')->nullable()->index();
            $table->unsignedBigInteger('student_id')->nullable()->index();
            $table->string('customer_name');
            $table->string('customer_email')->nullable();
            $table->string('customer_phone', 30)->nullable();
            $table->text('customer_address')->nullable();

            // Subscription details snapshot
            $table->string('description')->nullable();
            $table->enum('plan', ['monthly', 'yearly']);
            $table->date('billing_period_start');
            $table->date('billing_period_end');

            // Financial amounts — stored as decimal, backend-authoritative
            $table->decimal('subtotal', 10, 2)->default(0);
            $table->decimal('discount', 10, 2)->default(0);
            $table->decimal('tax', 10, 2)->default(0);
            $table->decimal('total', 10, 2);
            $table->string('currency', 3)->default('USD');

            // Status lifecycle: issued → paid | void
            $table->enum('status', ['issued', 'paid', 'void'])->default('issued')->index();

            // Timestamps for lifecycle events
            $table->timestamp('issued_at')->nullable();
            $table->timestamp('paid_at')->nullable();
            $table->timestamp('voided_at')->nullable();
            $table->text('void_reason')->nullable();

            // Who created/voided (FK to users — safe nullOnDelete so history is kept)
            $table->unsignedBigInteger('created_by')->nullable()->index();
            $table->unsignedBigInteger('voided_by')->nullable()->index();

            // PDF storage
            $table->string('pdf_path')->nullable();
            $table->string('pdf_sha256', 64)->nullable();

            // Idempotency — prevents duplicate invoices from double-submit
            $table->string('idempotency_key', 64)->nullable()->unique();

            $table->timestamps();

            // Composite indexes for common queries
            $table->index(['customer_type', 'status']);
            $table->index(['school_id', 'status']);
            $table->index(['student_id', 'status']);
            $table->index('issued_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('invoices');
    }
};
