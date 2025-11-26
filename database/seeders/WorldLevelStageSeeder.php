<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use App\Models\World;
use App\Models\Level;
use App\Models\Stage;
use App\Models\Exercise;

class WorldLevelStageSeeder extends Seeder
{
    public function run()
    {
        DB::transaction(function () {
            DB::table('exercises')->delete();
            DB::table('stages')->delete();
            DB::table('levels')->delete();
            DB::table('worlds')->delete();

            $alphabetWorld = World::create([
                'name' => 'ព្យញ្ជនៈខ្មែរ',
                'description' => 'រៀនគូរព្យញ្ជនៈខ្មែរ',
                'icon_url' => null,
                'map_image_url' => null,
                'theme_color' => '#4CAF50',
                'order_index' => 1,
                'is_active' => true,
            ]);

            $numbersWorld = World::create([
                'name' => 'លេខខ្មែរ',
                'description' => 'រៀនគូរលេខខ្មែរ',
                'icon_url' => null,
                'map_image_url' => null,
                'theme_color' => '#2196F3',
                'order_index' => 2,
                'is_active' => true,
            ]);

            $alphabetLevels = [
                [
                    'name' => 'ក​ - ឃ',
                    'description' => 'ព្យញ្ជនៈមូលដ្ឋាន',
                    'order_index' => 1,
                    'background_image' => null,
                    'required_stars' => 0,
                ],
                [
                    'name' => 'ង - ជ',
                    'description' => 'ព្យញ្ជនៈបន្ត',
                    'order_index' => 2,
                    'background_image' => null,
                    'required_stars' => 0,
                ],
                [
                    'name' => 'ឈ - ឋ',
                    'description' => 'ព្យញ្ជនៈបន្ត',
                    'order_index' => 3,
                    'background_image' => null,
                    'required_stars' => 0,
                ],
            ];

            $numberLevels = [
                [
                    'name' => 'លេខ 0-៤',
                    'description' => 'រៀនលេខពីសូន្យដល់បួន',
                    'order_index' => 1,
                    'background_image' => null,
                    'required_stars' => 0,
                ],
                [
                    'name' => 'លេខ ៥-៩',
                    'description' => 'រៀនលេខពីប្រាំដល់ប្រាំបួន',
                    'order_index' => 2,
                    'background_image' => null,
                    'required_stars' => 8,
                ],
            ];

            foreach ($alphabetLevels as $levelData) {
                $level = Level::create(array_merge($levelData, [
                    'world_id' => $alphabetWorld->id,
                ]));

                for ($stageOrder = 1; $stageOrder <= 3; $stageOrder++) {
                    $stage = Stage::create([
                        'level_id' => $level->id,
                        'name' => "Stage {$stageOrder}",
                        'description' => "Practice session {$stageOrder} for {$level->name}",
                        'instruction' => "Trace the Khmer characters following the guided path",
                        'order_index' => $stageOrder,
                        'max_stars' => 3,
                    ]);

                    $this->createExercisesForStage($stage, $level->name, $stageOrder);
                }
            }

            foreach ($numberLevels as $levelData) {
                $level = Level::create(array_merge($levelData, [
                    'world_id' => $numbersWorld->id,
                ]));

                for ($stageOrder = 1; $stageOrder <= 3; $stageOrder++) {
                    $stage = Stage::create([
                        'level_id' => $level->id,
                        'name' => "Stage {$stageOrder}",
                        'description' => "Practice session {$stageOrder} for {$level->name}",
                        'instruction' => "Trace the Khmer numbers following the guided path",
                        'order_index' => $stageOrder,
                        'max_stars' => 3,
                    ]);

                    $this->createExercisesForStage($stage, $level->name, $stageOrder);
                }
            }
        });
    }

    private function createExercisesForStage($stage, $levelName, $stageOrder)
    {
        $exercises = [];

        if (str_contains($levelName, 'ព្យញ្ជនៈ')) {
            $consonants = ['ក', 'ខ', 'គ', 'ឃ', 'ង', 'ច', 'ឆ', 'ជ', 'ឈ', 'ញ', 'ដ', 'ឋ', 'ឌ', 'ឍ', 'ណ', 'ត', 'ថ', 'ទ', 'ធ', 'ន',
                           'ប', 'ផ', 'ព', 'ភ', 'ម', 'យ', 'រ', 'ល', 'វ', 'ស', 'ហ', 'ឡ', 'អ'];
            $exercises = array_slice($consonants, ($stageOrder - 1) * 4, 4);
        } elseif (str_contains($levelName, 'ស្រៈ')) {
            $vowels = ['ា', 'ិ', 'ី', 'ឹ', 'ឺ', 'ុ', 'ូ', 'ួ', 'ើ', 'ឿ'];
            $exercises = array_slice($vowels, ($stageOrder - 1) * 3, 3);
        } elseif (str_contains($levelName, 'Advanced')) {
            $advanced = ['ំ', 'ះ', 'ៈ', '៉', '៊', '់', '៌', '៍', '៎', '៏'];
            $exercises = array_slice($advanced, ($stageOrder - 1) * 3, 3);
        } elseif (str_contains($levelName, '1-5')) {
            $exercises = ['១', '២', '៣', '៤', '៥'];
            $exercises = array_slice($exercises, ($stageOrder - 1) * 3, 3);
        } elseif (str_contains($levelName, '6-10')) {
            $exercises = ['៦', '៧', '៨', '៩', '១០'];
            $exercises = array_slice($exercises, ($stageOrder - 1) * 3, 3);
        } elseif (str_contains($levelName, 'Teen')) {
            $exercises = ['១១', '១២', '១៣', '១៤', '១៥', '១៦', '១៧', '១៨', '១៩'];
            $exercises = array_slice($exercises, ($stageOrder - 1) * 3, 3);
        }

        foreach ($exercises as $index => $character) {
            Exercise::create([
                'stage_id' => $stage->id,
                'prompt' => "Draw the Khmer character: {$character}",
                'character' => $character,
                'question' => "Trace the character {$character}",
                'options' => json_encode([$character, 'ម', 'រ', 'ល']),
                'instruction' => "Follow the stroke order to draw {$character} correctly",
                'hint' => "Start from the top left and follow the guided path",
                'order_index' => $index + 1,
            ]);
        }
    }


}
