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
        Schema::create('student_level_progress', function (Blueprint $table) {
            $table->id();
            $table->foreignId('student_id')->constrained('students');
            $table->foreignId('level_id')->constrained('levels');

            $table->integer('total_stars')->default(0);
            $table->boolean('is_completed')->default(false);
            $table->boolean('is_unlocked')->default(false);

            $table->timestamps();

            $table->unique(['student_id', 'level_id']);
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('student_level_progress');
    }
};
