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
        Schema::create('students', function (Blueprint $table) {
            $table->id();
            $table->string('firebase_uid')->nullable();
            $table->foreignId('school_id')->constrained('schools');

            $table->string('first_name');
            $table->string('last_name');
            $table->date('date_of_birth');
            $table->enum('gender', ['male', 'female', 'other']);
            $table->string('email')->unique()->nullable();
            $table->string('phone')->unique();
            $table->string('password');

            $table->string('parent_first_name')->nullable();
            $table->string('parent_last_name')->nullable();
            $table->string('parent_email')->nullable();
            $table->string('parent_phone')->nullable();

            $table->text('address')->nullable();
            $table->date('data_of_enrollment')->nullable();

            $table->boolean('is_active')->default(true);
            $table->string('school_key');

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
        Schema::dropIfExists('students');
    }
};
