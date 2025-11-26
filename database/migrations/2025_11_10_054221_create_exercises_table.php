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
        Schema::create('exercises', function (Blueprint $table) {
            $table->id();
            $table->foreignId('stage_id')->constrained()->onDelete('cascade');

            $table->string('prompt')->nullable();
            $table->string('character')->nullable();

            $table->string('question')->nullable();
            $table->json('options')->nullable();
            $table->string('correct_answer')->nullable();
            $table->text('instruction')->nullable();
            $table->text('hint')->nullable();

            $table->integer('order_index')->default(1);
            $table->string('audio_url')->nullable();
            $table->string('image_url')->nullable();
            // $table->integer('max_points')->default(1);
            // $table->integer('time_limit')->nullable();
            // $table->enum('difficulty', ['easy', 'medium', 'hard'])->default('easy');
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
        Schema::dropIfExists('exercises');
    }
};
