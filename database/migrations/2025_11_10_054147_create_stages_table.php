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
        Schema::create('stages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('level_id')->constrained()->onDelete('cascade');

            $table->boolean('is_unlocked_by_default')->default(false);
            $table->boolean('is_active')->default(true);

            $table->string('name');
            // $table->text('instruction')->nullable();
            $table->text('description')->nullable();

            $table->string('name_en');
            $table->text('description_en')->nullable();

            $table->integer('order_index');
            // $table->integer('max_stars')->default(3);
            $table->timestamps();

            $table->index(['level_id', 'is_active']);
            $table->index(['level_id', 'order_index']);
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('stages');
    }
};
