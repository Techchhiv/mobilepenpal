<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('subscriptions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('school_id')->nullable()->constrained()->onDelete('cascade');
            $table->foreignId('student_id')->nullable()->index();
            $table->enum('plan', ['monthly', 'yearly']);
            $table->decimal('amount', 10, 2);
            $table->date('start_date');
            $table->date('end_date')->index();
            $table->boolean('active')->default(true);
            $table->timestamps();

            $table->index(['school_id', 'active']);
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('subscriptions');
    }
};
