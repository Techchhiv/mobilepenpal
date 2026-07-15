<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('exercises', function (Blueprint $table) {
            $table->id();

            $table->string('prompt')->nullable();
            $table->string('character')->nullable();

            $table->string('question')->nullable();
            $table->json('options')->nullable();
            $table->string('correct_answer')->nullable();
            $table->text('instruction')->nullable();
            $table->text('example')->nullable();
            $table->text('hint')->nullable();


            $table->enum('character_type', ['digits', 'consonants', 'dependent_vowels', 'independent_vowels', 'math', 'diacritics'])->default('consonants');
            $table->enum('math_op', ['add', 'sub', 'mul', 'div'])->nullable();
            $table->enum('difficulty', ['easy', 'medium', 'hard', 'very_hard'])->default('easy');
            $table->index(['character_type', 'difficulty', 'math_op']);
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
