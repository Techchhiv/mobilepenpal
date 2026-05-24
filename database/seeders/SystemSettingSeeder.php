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
                    'billing_cycle' => 'month',
                    'contact_phone' => '+855 935 248 60',
                    'contact_email' => 'nginkimlong@gmail.com',
                ]),
                'created_at' => now(),
                'updated_at' => now(),
            ]
        );
    }
}
