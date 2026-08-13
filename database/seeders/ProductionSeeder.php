<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class ProductionSeeder extends Seeder
{
    /**
     * Seed the database safely for production environment without wiping data.
     *
     * @return void
     */
    public function run()
    {
        $this->call([
            RbacSeeder::class,
            SchoolSeeder::class,
            ExerciseSeeder::class,
            SystemSettingSeeder::class,
            MiniGameSeeder::class,
            QuestionTemplateSeeder::class,
            WorldPremiumResetSeeder::class,
        ]);
    }
}
