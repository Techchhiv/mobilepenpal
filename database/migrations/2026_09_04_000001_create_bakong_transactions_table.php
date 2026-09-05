<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('bakong_transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('student_id')->constrained('students')->cascadeOnDelete();
            $table->enum('plan', ['monthly', 'yearly'])->default('monthly');
            $table->decimal('amount', 10, 2);
            $table->string('currency', 3)->default('USD');
            $table->text('qr_string');
            $table->string('md5', 32)->unique();
            $table->enum('status', ['pending', 'completed', 'expired', 'failed'])->default('pending')->index();
            $table->string('bakong_hash', 100)->nullable();
            $table->string('from_account', 100)->nullable();
            $table->foreignId('invoice_id')->nullable()->constrained('invoices')->nullOnDelete();
            $table->foreignId('subscription_id')->nullable()->constrained('subscriptions')->nullOnDelete();
            $table->timestamp('expires_at')->nullable();
            $table->timestamps();

            $table->index(['student_id', 'status']);
        });

        // Add 'bakong' to payments table payment_method enum if using MySQL
        try {
            DB::statement("ALTER TABLE payments MODIFY COLUMN payment_method ENUM('cash', 'aba', 'bank_transfer', 'bakong', 'other')");
        } catch (\Throwable $e) {
            // fallback if not mysql or already supported
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('bakong_transactions');

        try {
            DB::statement("ALTER TABLE payments MODIFY COLUMN payment_method ENUM('cash', 'aba', 'bank_transfer', 'other')");
        } catch (\Throwable $e) {
        }
    }
};
