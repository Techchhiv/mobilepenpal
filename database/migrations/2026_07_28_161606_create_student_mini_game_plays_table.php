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
        Schema::create('student_mini_game_plays', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('student_id');
            $table->unsignedBigInteger('mini_game_id');
            $table->date('played_at');
            $table->unsignedInteger('play_count')->default(0);
            $table->timestamps();

            $table->unique(['student_id', 'mini_game_id', 'played_at']);
            $table->foreign('student_id')->references('id')->on('students')->onDelete('cascade');
            $table->foreign('mini_game_id')->references('id')->on('mini_games')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('student_mini_game_plays');
    }
};
