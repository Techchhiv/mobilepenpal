<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('schools', function (Blueprint $table) {
            $table->id();
            $table->string('name')->unique();
            $table->string('slug')->unique();
            $table->string('school_key')->unique();
            $table->string('admin_email')->nullable(); // ✅ link to admin email
            $table->boolean('is_active')->default(true)->index();
            $table->timestamps();
        });

       
    }

    public function down(): void
    {
        Schema::dropIfExists('schools');

        Schema::table('users', function (Blueprint $table) {
            $table->dropConstrainedForeignId('school_id');
        });
    }
};
