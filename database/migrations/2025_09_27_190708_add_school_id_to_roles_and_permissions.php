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
    Schema::table('roles', function($table) {
        $table->unsignedBigInteger('school_id')->nullable()->after('guard_name');
    });

    Schema::table('permissions', function($table) {
        $table->unsignedBigInteger('school_id')->nullable()->after('guard_name');
    });
}

public function down()
{
    Schema::table('roles', function($table) {
        $table->dropColumn('school_id');
    });
    Schema::table('permissions', function($table) {
        $table->dropColumn('school_id');
    });
}

};
