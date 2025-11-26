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
        Schema::create('student_world_progress', function (Blueprint $table) {
            $table->id();
            $table->foreignId('student_id')->constrained()->onDelete('cascade');
            $table->foreignId('world_id')->constrained()->onDelete('cascade');
            $table->unique(['student_id', 'world_id']);

            $table->integer('total_stars_earned')->default(0);
            $table->integer('completion_percentage')->default(0);
            $table->boolean('is_completed')->default(false);
            $table->boolean('is_unlocked')->default(false);

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
        Schema::dropIfExists('student_world_progress');
    }
};
