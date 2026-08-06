<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('classroom_enrollments', function (Blueprint $table) {
            $table->id();

            $table->foreignId('classroom_id')
                ->constrained()
                ->cascadeOnDelete();

            $table->foreignId('student_id')
                ->constrained()
                ->cascadeOnDelete();

            $table->enum('status', ['enrolled', 'removed', 'completed'])
                ->default('enrolled');

            $table->timestamp('enrolled_at')->useCurrent();
            $table->timestamp('left_at')->nullable();

            $table->timestamps();

            $table->unique(['student_id']);
            $table->index('classroom_id');
            $table->index(['classroom_id', 'status']);
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('classroom_enrollments');
    }
};
