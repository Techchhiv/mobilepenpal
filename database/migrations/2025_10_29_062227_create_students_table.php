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
            $table->foreignId('school_id')->constrained('schools');
            // $table->foreignId('branch_id')->nullable()->constrained('branches');
            $table->string('firebase_uid')->nullable();
            $table->string('school_key');

            $table->string('first_name');
            $table->string('last_name')->nullable();
            $table->string('nickname')->nullable();
            $table->integer('age')->nullable();
            $table->enum('gender', ['male','female','other']);
            $table->date('date_of_birth');
            $table->string('avatar')->nullable();

            $table->enum('mode', ['student','parent'])->default('student');
            $table->string('parent_pin')->nullable();
            // $table->timestamp('last_mode_switched')->nullable();

            $table->string('parent_first_name')->nullable();
            $table->string('parent_last_name')->nullable();
            $table->string('email')->unique()->nullable();
            $table->string('phone')->unique()->nullable();
            $table->string('password')->nullable();

            $table->integer('level')->default(1);
            $table->integer('streak')->default(0);
            $table->integer('time_spent')->default(0);
            $table->timestamp('last_played')->nullable();

            $table->string('address')->nullable();
            $table->string('enrollment_year')->nullable();
            $table->boolean('is_active')->default(true);
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
