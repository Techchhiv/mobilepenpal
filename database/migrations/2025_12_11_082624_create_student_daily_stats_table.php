<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('student_daily_stats', function (Blueprint $table) {
            $table->id();

            $table->foreignId('classroom_id')
                ->nullable()
                ->constrained('classrooms')
                ->nullOnDelete(); // safer than cascade if you want to keep stats history

            $table->foreignId('student_id')
                ->constrained('students')
                ->cascadeOnDelete();

            $table->date('date');

            $table->integer('exercises_attempted')->default(0);
            $table->integer('correct_attempts')->default(0);
            $table->integer('incorrect_attempts')->default(0);

            $table->integer('stages_completed')->default(0);
            $table->integer('stars_earned')->default(0);
            $table->integer('time_spent_seconds')->default(0);

            $table->timestamps();

            $table->unique(
                ['student_id', 'classroom_id', 'date'],
                'student_daily_stats_student_classroom_date_unique'
            );

            $table->index(['student_id', 'date'], 'student_daily_stats_student_date_idx');
            $table->index(['classroom_id', 'date'], 'student_daily_stats_classroom_date_idx');
        });
    }

    public function down()
    {
        Schema::dropIfExists('student_daily_stats');
    }
};
