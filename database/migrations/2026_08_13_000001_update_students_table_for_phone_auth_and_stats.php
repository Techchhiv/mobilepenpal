<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        if (Schema::hasTable('students')) {
            Schema::table('students', function (Blueprint $table) {
                if (!Schema::hasColumn('students', 'coin')) {
                    $table->integer('coin')->default(0);
                }
                if (!Schema::hasColumn('students', 'xp')) {
                    $table->integer('xp')->default(0);
                }
                if (!Schema::hasColumn('students', 'streak')) {
                    $table->integer('streak')->default(0);
                }
                if (!Schema::hasColumn('students', 'unlocked_avatars')) {
                    $table->json('unlocked_avatars')->nullable();
                }
            });

            // Adjust email to be nullable and phone to be required (matching phone auth)
            // Direct SQL statements avoid Doctrine DBAL incompatibility errors
            $driver = DB::getDriverName();
            if ($driver === 'mysql' || $driver === 'mariadb') {
                DB::statement("ALTER TABLE `students` MODIFY COLUMN `email` VARCHAR(255) NULL");
                DB::statement("ALTER TABLE `students` MODIFY COLUMN `phone` VARCHAR(255) NOT NULL");
            } elseif ($driver === 'pgsql') {
                DB::statement("ALTER TABLE students ALTER COLUMN email DROP NOT NULL");
                DB::statement("ALTER TABLE students ALTER COLUMN phone SET NOT NULL");
            }
        }
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        if (Schema::hasTable('students')) {
            Schema::table('students', function (Blueprint $table) {
                if (Schema::hasColumn('students', 'coin')) {
                    $table->dropColumn('coin');
                }
                if (Schema::hasColumn('students', 'xp')) {
                    $table->dropColumn('xp');
                }
                if (Schema::hasColumn('students', 'streak')) {
                    $table->dropColumn('streak');
                }
                if (Schema::hasColumn('students', 'unlocked_avatars')) {
                    $table->dropColumn('unlocked_avatars');
                }
            });
        }
    }
};
