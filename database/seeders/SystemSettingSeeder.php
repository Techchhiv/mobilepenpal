<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class SystemSettingSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        DB::table('system_settings')->updateOrInsert(
            ['key' => 'subscription'],
            [
                'value' => json_encode([
                    'price' => 5.0,
                    'discount' => 50,
                    'tax_rate' => 0,
                    'billing_cycle' => 'month',
                    'contact_phone' => '+855 935 248 60',
                    'contact_email' => 'info@khmerpenpal.com',
                ]),
                'created_at' => now(),
                'updated_at' => now(),
            ]
        );

        DB::table('system_settings')->updateOrInsert(
            ['key' => 'feature_locks'],
            [
                'value' => json_encode([
                    'enabled' => true,
                    'mini_game_free_daily_limit' => 3,
                    'ai_writing_free_char_limit' => 4,
                    'learning_free_stage_limit' => 10,
                ]),
                'created_at' => now(),
                'updated_at' => now(),
            ]
        );
    }
}
