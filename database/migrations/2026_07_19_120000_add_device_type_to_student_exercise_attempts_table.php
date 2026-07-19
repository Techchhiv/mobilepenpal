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
        Schema::table('student_exercise_attempts', function (Blueprint $table) {
            if (!Schema::hasColumn('student_exercise_attempts', 'device_type')) {
                $table->string('device_type', 16)->nullable()->after('math_op');
            }
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('student_exercise_attempts', function (Blueprint $table) {
            if (Schema::hasColumn('student_exercise_attempts', 'device_type')) {
                $table->dropColumn('device_type');
            }
        });
    }
};
