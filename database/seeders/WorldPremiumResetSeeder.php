<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class WorldPremiumResetSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        if (Schema::hasTable('worlds') && Schema::hasColumn('worlds', 'is_premium')) {
            DB::table('worlds')->update(['is_premium' => false]);
        }

        if (Schema::hasTable('levels') && Schema::hasColumn('levels', 'is_premium')) {
            DB::table('levels')->update(['is_premium' => false]);
        }
    }
}
