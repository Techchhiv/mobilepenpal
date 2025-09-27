<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('teachers', function (Blueprint $table) {
            $table->id(); // internal ID
            $table->unsignedBigInteger('school_id'); // link to school
            $table->string('teacher_id')->unique(); // login identity
            $table->string('name');
            $table->string('email')->unique();
            $table->string('phone')->nullable();
            $table->string('subject')->nullable();
            $table->string('photo')->nullable();
            $table->string('password'); // hashed password
            $table->string('school_key'); // assigned school key
            $table->timestamps();

            $table->foreign('school_id')->references('id')->on('schools')->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('teachers');
    }
};
