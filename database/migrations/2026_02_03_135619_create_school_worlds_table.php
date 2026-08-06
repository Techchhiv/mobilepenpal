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
        Schema::create('school_worlds', function (Blueprint $table) {
            $table->id();

            $table->foreignId('school_id')
                ->constrained('schools')
                ->cascadeOnDelete();

            $table->foreignId('world_id')
                ->constrained('worlds')
                ->cascadeOnDelete();

            $table->unsignedInteger('order_index');
            $table->boolean('is_enabled')->default(true);

            $table->timestamps();

            $table->unique(['school_id', 'world_id']);
            $table->index(['school_id', 'is_enabled']);
            $table->index(['school_id', 'order_index']);
            $table->index('world_id');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('school_worlds');
    }
};
