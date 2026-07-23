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
        Schema::create('levels', function (Blueprint $table) {
            $table->id();
            $table->foreignId('world_id')->constrained()->onDelete('cascade');

            $table->boolean('is_active')->default(true);
            $table->boolean('is_premium')->default(false);
            $table->boolean('is_unlocked_by_default')->default(false);

            $table->string('name');
            $table->text('description')->nullable();

            $table->string('name_en');
            $table->text('description_en')->nullable();
            $table->integer('order_index');

            $table->timestamps();

            $table->index(['world_id', 'is_active']);
            $table->index(['world_id', 'order_index']);
            $table->index(['world_id', 'is_active', 'order_index']);
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('levels');
    }
};
