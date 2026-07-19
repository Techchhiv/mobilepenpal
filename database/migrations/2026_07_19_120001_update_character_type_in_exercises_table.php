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
        // Update the character_type enum to include 'diacritics'
        // Using raw SQL because Laravel's enum change doesn't support adding values cleanly
        DB::statement("ALTER TABLE `exercises` MODIFY COLUMN `character_type` ENUM('digits','consonants','dependent_vowels','independent_vowels','math','diacritics') DEFAULT 'consonants'");
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        DB::statement("ALTER TABLE `exercises` MODIFY COLUMN `character_type` ENUM('digits','consonants','dependent_vowels','independent_vowels','math') DEFAULT 'consonants'");
    }
};
