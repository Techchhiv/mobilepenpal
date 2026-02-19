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
        Schema::create('worlds', function (Blueprint $table) {
            $table->id();
            $table->foreignId('school_id')
                ->nullable()
                ->constrained('schools')
                ->nullOnDelete();
            $table->enum('audience', ['public', 'schools', 'assigned'])->default('public')->index();

            $table->string('name');
            $table->text('description')->nullable();

            $table->string('name_en');
            $table->text('description_en')->nullable();

            // $table->string('icon_url')->nullable();
            // $table->string('map_image_url')->nullable();
            // $table->string('theme_color')->nullable();

            $table->integer('order_index');
            $table->boolean('is_active')->default(true);
            $table->boolean('is_unlocked_by_default')->default(false);
            $table->timestamps();

            $table->index(['school_id', 'is_active']);
            $table->index(['school_id', 'order_index']);
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('worlds');
    }
};
