<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('roles', function (Blueprint $table) {
            if (!Schema::hasColumn('roles', 'school_id')) {
                $table->unsignedBigInteger('school_id')->nullable()->after('guard_name')->index();
            }
        });

        Schema::table('roles', function (Blueprint $table) {
            // You may need to adjust the index name depending on your DB
            try { $table->dropUnique('roles_name_guard_name_unique'); } catch (\Throwable $e) {}
        });

        Schema::table('roles', function (Blueprint $table) {
            // Unique per (name, guard, school)
            $table->unique(['name','guard_name','school_id'], 'roles_name_guard_school_unique');
        });
    }

    public function down(): void
    {
        Schema::table('roles', function (Blueprint $table) {
            try { $table->dropUnique('roles_name_guard_school_unique'); } catch (\Throwable $e) {}
            $table->unique(['name','guard_name'], 'roles_name_guard_name_unique');
            $table->dropColumn('school_id');
        });
    }
};
