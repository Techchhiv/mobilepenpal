<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('payments', function (Blueprint $table) {
            $table->id();

            // The invoice this payment settles
            $table->foreignId('invoice_id')->constrained('invoices')->restrictOnDelete();

            // Amount paid
            $table->decimal('amount', 10, 2);
            $table->string('currency', 3)->default('USD');

            // How payment was made
            $table->enum('payment_method', ['cash', 'aba', 'bank_transfer', 'other']);

            // Reference number / transaction ID from the payment provider (not sensitive credentials)
            $table->string('payment_reference')->nullable();

            // Payment status (extensible for future partial/refund states)
            $table->enum('status', ['completed', 'refunded'])->default('completed');

            $table->timestamp('paid_at');

            // Who recorded this payment
            $table->unsignedBigInteger('recorded_by')->nullable()->index();

            $table->text('notes')->nullable();

            $table->timestamps();

            $table->index(['invoice_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payments');
    }
};
