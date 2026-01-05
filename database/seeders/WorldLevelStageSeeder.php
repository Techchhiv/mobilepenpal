<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use App\Models\World;
use App\Models\Level;
use App\Models\Stage;
use App\Models\Exercise;
use App\Models\StageExercise;

class WorldLevelStageSeeder extends Seeder
{
    /** @var array<string, \App\Models\Exercise> */
    protected array $exerciseBank = [];

    public function run()
    {
        DB::transaction(function () {
            DB::table('stage_exercises')->delete();
            DB::table('student_exercise_attempts')->delete();
            DB::table('exercises')->delete();
            DB::table('stages')->delete();
            DB::table('levels')->delete();
            DB::table('worlds')->delete();

            $consonants = [
                'ក', 'ខ', 'គ', 'ឃ', 'ង',
                'ច', 'ឆ', 'ជ', 'ឈ', 'ញ',
                'ដ', 'ឋ', 'ឌ', 'ឍ', 'ណ',
                'ត', 'ថ', 'ទ', 'ធ', 'ន',
                'ប', 'ផ', 'ព', 'ភ', 'ម',
                'យ', 'រ', 'ល', 'វ',
                'ស', 'ហ', 'ឡ', 'អ',
            ];

            $digits = ['០','១','២','៣','៤','៥','៦','៧','៨','៩'];

            $independentVowels = ['ឥ','ឦ','ឧ','ឩ','ឪ','ឫ','ឬ','ឭ','ឮ','ឯ','ឰ','ឱ','ឲ','ឪ'];

            $dependentVowels = ['ា','ិ','ី','ឹ','ឺ','ុ','ូ','ួ','ើ','ឿ','ៀ','េ','ែ','ៃ','ោ','ៅ','ុំ','ំ','ាំ','ះ','ិះ','ុះ','េះ','ោះ'];

            $worlds = [
                [
                    'key' => 'consonants',
                    'name' => 'ព្យញ្ជនៈខ្មែរ',
                    'description' => 'រៀនគូរព្យញ្ជនៈខ្មែរ',
                    'theme_color' => '#4CAF50',
                    'order_index' => 1,
                    'chars' => $consonants,
                    'character_type' => 'consonants',
                    'chunk' => 5,
                ],
                [
                    'key' => 'digits',
                    'name' => 'លេខខ្មែរ',
                    'description' => 'រៀនគូរលេខខ្មែរ',
                    'theme_color' => '#2196F3',
                    'order_index' => 2,
                    'chars' => $digits,
                    'character_type' => 'digits',
                    'chunk' => 5,
                ],
                [
                    'key' => 'dependent_vowels',
                    'name' => 'ស្រៈនិស្ស័យ',
                    'description' => 'រៀនគូរស្រៈនិស្ស័យ',
                    'theme_color' => '#9C27B0',
                    'order_index' => 4,
                    'chars' => $dependentVowels,
                    'character_type' => 'dependent_vowels',
                    'chunk' => 5,
                ],
                [
                    'key' => 'independent_vowels',
                    'name' => 'ស្រៈពេញតួ',
                    'description' => 'រៀនគូរស្រៈពេញតួ',
                    'theme_color' => '#FF9800',
                    'order_index' => 3,
                    'chars' => $independentVowels,
                    'character_type' => 'independent_vowels',
                    'chunk' => 5,
                ],
            ];

            foreach ($worlds as $w) {
                $world = World::create([
                    'name'         => $w['name'],
                    'description'  => $w['description'],
                    'icon_url'     => null,
                    'map_image_url'=> null,
                    'theme_color'  => $w['theme_color'],
                    'order_index'  => $w['order_index'],
                    'is_active'    => true,
                ]);

                $bank = $this->createExerciseBank($w['chars'], $w['character_type']);

                $chunks = array_chunk($w['chars'], $w['chunk']);
                foreach ($chunks as $levelIndex => $levelChars) {
                    $levelName = $this->makeLevelName($w['key'], $levelIndex, $levelChars);

                    $level = Level::create([
                        'world_id' => $world->id,
                        'name' => $levelName,
                        'description' => "Level " . ($levelIndex + 1),
                        'order_index' => $levelIndex + 1,
                        'background_image' => null,
                    ]);

                    foreach ($levelChars as $stageIndex => $ch) {
                        $stage = Stage::create([
                            'level_id'    => $level->id,
                            'name'        => "រៀន {$ch}",
                            'description' => "Practice session for {$ch}",
                            'instruction' => "Trace {$ch} following the guided path",
                            'order_index' => $stageIndex + 1,
                            'max_stars'   => 3,
                        ]);

                        $this->attachExerciseToStage($stage, $bank[$ch], 1, 3);
                    }
                }
            }
        });
    }

    /**
     * @param array<string> $characters
     * @return array<string, Exercise>
     */
    private function createExerciseBank(array $characters, string $characterType): array
    {
        $bank = [];

        foreach ($characters as $character) {
            $bank[$character] = Exercise::create([
                'prompt'        => "Draw: {$character}",
                'character'     => $character,
                'question'      => "Trace: {$character}",
                'options'       => json_encode([$character]),
                'instruction'   => "Follow the stroke order to draw {$character}",
                'hint'          => "Follow the guided path",
                'example'       => $this->buildExampleForCharacter($character, $characterType),
                'character_type'=> $characterType,
            ]);
        }

        return $bank;
    }

    private function attachExerciseToStage(Stage $stage, Exercise $exercise, int $orderIndex = 1, int $repeatCount = 3): void
    {
        StageExercise::insert([
            'stage_id'     => $stage->id,
            'exercise_id'  => $exercise->id,
            'order_index'  => $orderIndex,
            'repeat_count' => $repeatCount,
            'created_at'   => now(),
            'updated_at'   => now(),
        ]);
    }

    private function makeLevelName(string $worldKey, int $levelIndex, array $charsInLevel): string
    {
        $first = $charsInLevel[0] ?? '';
        $last  = $charsInLevel[count($charsInLevel) - 1] ?? '';

        return match ($worldKey) {
            'consonants' => "{$first} - {$last}",
            'digits' => "លេខ {$first} - {$last}",
            'independent_vowels' => "ស្រៈឯករាជ្យ {$first} - {$last}",
            'dependent_vowels' => "ស្រៈព្យួរ {$first} - {$last}",
            default => "Level " . ($levelIndex + 1),
        };
    }

    private function buildExampleForCharacter(string $character, string $characterType): string
    {
        if ($characterType === 'consonants') {
            return "{$character} / {$character}ា / {$character}ិ / {$character}ី";
        }

        if ($characterType === 'digits') {
            return "{$character}";
        }

        return "{$character}";
    }
}
