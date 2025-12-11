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
        Schema::create('stage_exercises', function (Blueprint $table) {
            $table->id();
            $table->foreignId('stage_id')->constrained('stages');
            $table->foreignId('exercise_id')->constrained('exercises');

            $table->integer('order_index')->default(1);
            $table->integer('repeat_count')->default(3);

            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('stage_exercise');
    }
};
