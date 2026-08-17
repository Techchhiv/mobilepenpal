<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('subscriptions', function (Blueprint $table) {
            // Idempotency key — nullable for backward compatibility with existing records
            $table->string('idempotency_key', 64)->nullable()->unique()->after('active');

            // Fix student_id — add proper FK constraint (was missing).
            // Use nullOnDelete so deleting a student does NOT destroy subscription history.
            // First drop the plain index that was created in the original migration.
            $table->foreign('student_id')
                  ->references('id')
                  ->on('students')
                  ->nullOnDelete();
        });

        // Fix school_id FK: change from onDelete('cascade') to onDelete('set null')
        // so that deleting a school preserves subscription/invoice financial history.
        // We drop and re-add the FK constraint.
        Schema::table('subscriptions', function (Blueprint $table) {
            $table->dropForeign(['school_id']);
            $table->foreign('school_id')
                  ->references('id')
                  ->on('schools')
                  ->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('subscriptions', function (Blueprint $table) {
            $table->dropColumn('idempotency_key');

            $table->dropForeign(['student_id']);
            $table->dropForeign(['school_id']);

            // Restore original cascade behavior
            $table->foreign('school_id')
                  ->references('id')
                  ->on('schools')
                  ->onDelete('cascade');
        });
    }
};
