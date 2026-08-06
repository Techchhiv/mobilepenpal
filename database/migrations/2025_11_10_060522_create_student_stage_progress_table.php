<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
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
        Schema::create('student_stage_progress', function (Blueprint $table) {
            $table->id();
            $table->foreignId('student_id')->constrained('students');
            // $table->foreignId('classroom_id')->nullable()->constrained('classrooms');
            $table->foreignId('stage_id')->constrained('stages');

            $table->integer('stars_earned')->default(0);
            $table->enum('status',['locked', 'unlocked', 'completed'])->default('locked');

            $table->timestamps();

            $table->unique(['student_id', 'stage_id']);
            $table->index(['student_id', 'status']);
            $table->index('stage_id');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('student_stage_progress');
    }
};
