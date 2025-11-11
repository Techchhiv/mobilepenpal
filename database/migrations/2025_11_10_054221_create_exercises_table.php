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
            $table->foreignId('stage_id')->constrained('stages');
            $table->string('title')->nullable();
            $table->string('type')->default('khmer');
            $table->string('question')->nullable();
            $table->string('correct_answer')->nullable();
            $table->string('character')->nullable();
            $table->text('instruction')->nullable();
            $table->integer('order_index')->default(1);
            $table->integer('max_points')->default(10);
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
