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
        Schema::create('student_exercise_attempts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('student_id')->constrained('students');
            // $table->foreignId('classroom_id')->nullable()->constrained('classrooms');
            $table->foreignId('exercise_id')->constrained('exercises');

            $table->string('user_answer')->nullable();
            $table->json('stroke')->nullable();
            $table->string('label')->nullable();
            $table->string('math_op', 8)->nullable()->index();
            $table->string('device_type', 16)->nullable();
            // $table->integer('points_earned')->default(0);
            // $table->integer('time_taken')->nullable();
            $table->boolean('is_correct')->default(false);

            $table->timestamps();

            $table->index(['student_id', 'exercise_id']);
            $table->index(['student_id', 'created_at']);
            $table->index(['student_id', 'is_correct', 'created_at']);
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('student_exercise_attempts');
    }
};
