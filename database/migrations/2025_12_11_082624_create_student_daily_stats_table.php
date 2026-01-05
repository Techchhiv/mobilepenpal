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
        Schema::create('student_daily_stats', function (Blueprint $table) {
            $table->id();

            $table->foreignId('student_id')
                ->constrained('students')
                ->onDelete('cascade');

            $table->date('date');

            $table->integer('exercises_attempted')->default(0);
            $table->integer('correct_attempts')->default(0);
            $table->integer('incorrect_attempts')->default(0);

            $table->integer('stages_completed')->default(0);
            $table->integer('stars_earned')->default(0);
            $table->integer('time_spent_seconds')->default(0);

            $table->timestamps();

            $table->unique(['student_id', 'date']);
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('student_daily_stats');
    }
};
