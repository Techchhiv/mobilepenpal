<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class ProductionSeeder extends Seeder
{
    public function run()
    {
        $this->call([
            RbacSeeder::class,
            SchoolSeeder::class,
            ExerciseSeeder::class,
            SystemSettingSeeder::class,
            MiniGameSeeder::class,
            QuestionTemplateSeeder::class,
        ]);
    }
}
