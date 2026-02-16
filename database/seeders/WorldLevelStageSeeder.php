<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

use App\Models\World;
use App\Models\Level;
use App\Models\Stage;
use App\Models\Exercise;
use App\Models\StageExercise;
use Illuminate\Support\Facades\Log;

class WorldLevelStageSeeder extends Seeder
{
    public function run(): void
    {
        DB::transaction(function () {
            $this->cleanup();

            // -----------------------
            // Characters
            // -----------------------
            $consonants = [
                'ក',
                'ខ',
                'គ',
                'ឃ',
                'ង',
                'ច',
                'ឆ',
                'ជ',
                'ឈ',
                'ញ',
                'ដ',
                'ឋ',
                'ឌ',
                'ឍ',
                'ណ',
                'ត',
                'ថ',
                'ទ',
                'ធ',
                'ន',
                'ប',
                'ផ',
                'ព',
                'ភ',
                'ម',
                'យ',
                'រ',
                'ល',
                'វ',
                'ស',
                'ហ',
                'ឡ',
                'អ',
            ];

            $digits = ['០', '១', '២', '៣', '៤', '៥', '៦', '៧', '៨', '៩'];

            $independentVowels = [
                'ឥ',
                'ឦ',
                'ឧ',
                'ឩ',
                'ឪ',
                'ឫ',
                'ឬ',
                'ឭ',
                'ឮ',
                'ឯ',
                'ឰ',
                'ឱ',
                'ឲ',
                'ឪ'
            ];

            $dependentVowels = [
                'ា',
                'ិ',
                'ី',
                'ឹ',
                'ឺ',
                'ុ',
                'ូ',
                'ួ',
                'ើ',
                'ឿ',
                'ៀ',
                'េ',
                'ែ',
                'ៃ',
                'ោ',
                'ៅ',
                'ុំ',
                'ំ',
                'ាំ',
                'ះ',
                'ិះ',
                'ុះ',
                'េះ',
                'ោះ'
            ];

            $halfConsonants = array_slice($consonants, 0, 10);

            $worldDefs = [
                [
                    'key' => 'public_consonants_half',
                    'audience' => 'public',
                    'order_index' => 1,
                    'name_km' => 'ព្យញ្ជនៈ',
                    'name_en' => 'Consonants',
                    'desc_km' => 'រៀនគូរព្យញ្ជនៈខ្មែរ',
                    'desc_en' => 'Learn Khmer consonants',
                    'chars' => $halfConsonants,
                    'character_type' => 'consonants',
                    'chunk' => 5,
                    'is_unlocked_by_default'=> true,
                ],
                [
                    'key' => 'public_digits',
                    'audience' => 'public',
                    'order_index' => 2,
                    'name_km' => 'លេខ',
                    'name_en' => 'Digits',
                    'desc_km' => 'រៀនគូរលេខខ្មែរ',
                    'desc_en' => 'Learn Khmer digits',
                    'chars' => $digits,
                    'character_type' => 'digits',
                    'chunk' => 5,
                    'is_unlocked_by_default'=> true,
                ],
                // [
                //     'key' => 'public_math',
                //     'audience' => 'public',
                //     'order_index' => 3,
                //     'name_km' => 'គណិតវិទ្យា',
                //     'name_en' => 'Math',
                //     'desc_km' => 'ហាត់គណិតវិទ្យា (បូក ដក គុណ ចែក)',
                //     'desc_en' => 'Practice math (add, sub, mul, div)',
                //     'chars' => [],
                //     'character_type' => 'math',
                //     'chunk' => 5,
                // ],
                // [
                //     'key' => 'schools_math',
                //     'audience' => 'schools',
                //     'order_index' => 7,
                //     'name_km' => 'គណិតវិទ្យា',
                //     'name_en' => 'Math',
                //     'desc_km' => 'ហាត់គណិតវិទ្យា (បូក ដក គុណ ចែក)',
                //     'desc_en' => 'Practice math (add, sub, mul, div)',
                //     'chars' => [],
                //     'character_type' => 'math',
                //     'chunk' => 5,
                // ],

                // Schools (all school accounts can see)
                [
                    'key' => 'schools_consonants_full',
                    'audience' => 'schools',
                    'order_index' => 3,
                    'name_km' => 'ព្យញ្ជនៈ',
                    'name_en' => 'Consonants',
                    'desc_km' => 'រៀនគូរព្យញ្ជនៈខ្មែរ',
                    'desc_en' => 'Learn Khmer consonants',
                    'chars' => $consonants,
                    'character_type' => 'consonants',
                    'chunk' => 5,
                ],
                [
                    'key' => 'schools_digits',
                    'audience' => 'schools',
                    'order_index' => 4,
                    'name_km' => 'លេខ',
                    'name_en' => 'Digits',
                    'desc_km' => 'រៀនគូរលេខខ្មែរ',
                    'desc_en' => 'Learn Khmer digits',
                    'chars' => $digits,
                    'character_type' => 'digits',
                    'chunk' => 5,
                ],
                [
                    'key' => 'schools_independent_vowels',
                    'audience' => 'schools',
                    'order_index' => 5,
                    'name_km' => 'ស្រៈពេញតួ',
                    'name_en' => 'Independent Vowels',
                    'desc_km' => 'រៀនគូរស្រៈពេញតួ',
                    'desc_en' => 'Learn independent vowels',
                    'chars' => $independentVowels,
                    'character_type' => 'independent_vowels',
                    'chunk' => 5,
                ],
                [
                    'key' => 'schools_dependent_vowels',
                    'audience' => 'schools',
                    'order_index' => 6,
                    'name_km' => 'ស្រៈនិស្ស័យ',
                    'name_en' => 'Dependent Vowels',
                    'desc_km' => 'រៀនគូរស្រៈនិស្ស័យ',
                    'desc_en' => 'Learn dependent vowels',
                    'chars' => $dependentVowels,
                    'character_type' => 'dependent_vowels',
                    'chunk' => 5,
                ],
            ];

            foreach ($worldDefs as $def) {
                $world = $this->createWorld(
                    audience: $def['audience'],
                    orderIndex: $def['order_index'],
                    nameKm: $def['name_km'],
                    nameEn: $def['name_en'],
                    descKm: $def['desc_km'],
                    descEn: $def['desc_en'],
                    unlocked: $def['is_unlocked_by_default'] ?? false
                );

                $this->seedWorldContent(
                    world: $world,
                    worldKey: $def['key'],
                    chars: $def['chars'],
                    characterType: $def['character_type'],
                    chunk: $def['chunk'],
                );
            }
        });
    }

    private function cleanup(): void
    {
        $this->safeDelete('stage_exercises');
        $this->safeDelete('student_exercise_attempts');
        $this->safeDelete('student_stage_progress');
        $this->safeDelete('student_level_progress');
        $this->safeDelete('student_world_progress');
        $this->safeDelete('student_sessions');
        $this->safeDelete('student_daily_stats');

        $this->safeDelete('exercises');
        $this->safeDelete('stages');
        $this->safeDelete('levels');

        $this->safeDelete('school_worlds');
        $this->safeDelete('worlds');
    }

    private function safeDelete(string $table): void
    {
        if (Schema::hasTable($table)) {
            DB::table($table)->delete();
        }
    }

    private function createWorld(
        string $audience,
        int $orderIndex,
        string $nameKm,
        string $nameEn,
        ?string $descKm,
        ?string $descEn,
        ?bool $unlocked = false
    ): World {
        $data = [
            'school_id' => null,
            'audience' => $audience,
            'order_index' => $orderIndex,
            'is_active' => true,
            'is_unlocked_by_default' => $unlocked,
            'name' => $nameKm,
            'description' => $descKm,
        ];

        if (Schema::hasColumn('worlds', 'name_en')) {
            $data['name_en'] = $nameEn;
        }
        if (Schema::hasColumn('worlds', 'description_en')) {
            $data['description_en'] = $descEn;
        }

        return World::create($data);
    }

    private function seedWorldContent(World $world, string $worldKey, array $chars, string $characterType, int $chunk = 5): void
    {
        if ($characterType === 'math') {
            $this->seedMathWorldContent($world);
            return;
        }

        $bank = $this->createExerciseBank($chars, $characterType);

        $chunks = array_chunk($chars, $chunk);

        foreach ($chunks as $levelIndex => $levelChars) {
            [$levelNameKm, $levelNameEn] = $this->makeLevelName($characterType, $levelChars);

            $levelData = [
                'world_id' => $world->id,
                'name' => $levelNameKm,
                'description' => "កម្រិត " . ($levelIndex + 1),
                'order_index' => $levelIndex + 1,
                'is_active' => true,
                'is_unlocked_by_default' => false,
            ];

            if (Schema::hasColumn('levels', 'name_en')) {
                $levelData['name_en'] = $levelNameEn;
            }
            if (Schema::hasColumn('levels', 'description_en')) {
                $levelData['description_en'] = "Level " . ($levelIndex + 1);
            }

            $level = Level::create($levelData);

            foreach ($levelChars as $stageIndex => $ch) {
                [$stageNameKm, $stageNameEn] = $this->makeStageName($characterType, $ch);

                $stageData = [
                    'level_id' => $level->id,
                    'name' => $stageNameKm,
                    'description' => "ហាត់សរសេរ {$ch}",
                    'order_index' => $stageIndex + 1,
                    // 'max_stars' => 3,
                    'is_active' => true,
                    'is_unlocked_by_default' => false,
                ];

                if (Schema::hasColumn('stages', 'name_en')) {
                    $stageData['name_en'] = $stageNameEn;
                }
                if (Schema::hasColumn('stages', 'description_en')) {
                    $stageData['description_en'] = "Practice session for {$ch}";
                }

                $stage = Stage::create($stageData);

                $this->attachExerciseToStage($stage, $bank[$ch], 1, 3);
            }
        }
    }

    /**
     * @return array<string, Exercise> keyed by character
     */
    private function createExerciseBank(array $characters, string $characterType): array
    {
        $bank = [];

        foreach ($characters as $character) {
            $existing = Exercise::where('character_type', $characterType)
                ->whereRaw('BINARY `character` = ?', [$character])
                ->first();

            if ($existing) {
                $existing->update([
                    'prompt' => "Draw: {$character}",
                    'question' => "Trace: {$character}",
                    'options' => json_encode([$character], JSON_UNESCAPED_UNICODE),
                    'instruction' => "Follow the stroke order to draw {$character}",
                    'hint' => "Follow the guided path",
                    'example' => $this->buildExampleForCharacter($character, $characterType),
                ]);
                $bank[$character] = $existing;
            } else {
                $bank[$character] = Exercise::create([
                    'character' => $character,
                    'character_type' => $characterType,
                    'prompt' => "Draw: {$character}",
                    'question' => "Trace: {$character}",
                    'options' => json_encode([$character], JSON_UNESCAPED_UNICODE),
                    'instruction' => "Follow the stroke order to draw {$character}",
                    'hint' => "Follow the guided path",
                    'example' => $this->buildExampleForCharacter($character, $characterType),
                ]);
            }
        }

        return $bank;
    }

    private function seedMathWorldContent(World $world): void
    {
        $difficulties = ['easy', 'medium', 'hard'];
        $ops = ['add', 'sub', 'mul', 'div'];

        $bank = $this->createMathExerciseBank($difficulties, $ops);

        $levelData = [
            'world_id' => $world->id,
            'name' => 'គណិតវិទ្យា',
            'description' => 'កម្រិតគណិតវិទ្យា',
            'order_index' => 1,
            'is_active' => true,
            'is_unlocked_by_default' => false,
        ];

        if (Schema::hasColumn('levels', 'name_en')) {
            $levelData['name_en'] = 'Math';
        }
        if (Schema::hasColumn('levels', 'description_en')) {
            $levelData['description_en'] = 'Math level';
        }

        $level = Level::create($levelData);

        foreach ($difficulties as $i => $diff) {
            [$kmName, $enName] = match ($diff) {
                'easy' => ['ងាយ', 'Easy'],
                'medium' => ['មធ្យម', 'Medium'],
                'hard' => ['ពិបាក', 'Hard'],
                default => [$diff, ucfirst($diff)],
            };

            $stageData = [
                'level_id' => $level->id,
                'name' => "គណិតវិទ្យា - {$kmName}",
                'description' => "ហាត់គណិតវិទ្យា ({$kmName})",
                'order_index' => $i + 1,
                'is_active' => true,
                'is_unlocked_by_default' => false,
            ];

            if (Schema::hasColumn('stages', 'name_en')) {
                $stageData['name_en'] = "Math - {$enName}";
            }
            if (Schema::hasColumn('stages', 'description_en')) {
                $stageData['description_en'] = "Practice math ({$enName})";
            }

            $stage = Stage::create($stageData);

            $order = 1;
            foreach ($ops as $op) {
                $this->attachExerciseToStage(
                    $stage,
                    $bank[$diff][$op],
                    orderIndex: $order++,
                    repeatCount: 3
                );
            }
        }
    }


    /**
     * @return array<string, array<string, Exercise>> bank[difficulty][op]
     */
    private function createMathExerciseBank(array $difficulties, array $ops): array
    {
        $bank = [];

        foreach ($difficulties as $diff) {
            foreach ($ops as $op) {
                $characterKey = "math_{$op}_{$diff}";

                $data = [
                    'prompt' => "Math ({$op}, {$diff})",
                    'question' => "Solve ({$op})",
                    'options' => null,
                    'correct_answer' => null,
                    'instruction' => "Solve the {$op} question",
                    'hint' => "Try again",
                    'example' => null,
                ];

                if (Schema::hasColumn('exercises', 'difficulty')) {
                    $data['difficulty'] = $diff;
                }

                if (Schema::hasColumn('exercises', 'math_op')) {
                    $data['math_op'] = $op;
                }

                $bank[$diff][$op] = Exercise::updateOrCreate(
                    [
                        'character' => $characterKey,
                        'character_type' => 'math',
                    ],
                    $data
                );
            }
        }

        return $bank;
    }


    private function attachExerciseToStage(Stage $stage, Exercise $exercise, int $orderIndex = 1, int $repeatCount = 3): void
    {
        StageExercise::create([
            'stage_id' => $stage->id,
            'exercise_id' => $exercise->id,
            'order_index' => $orderIndex,
            'repeat_count' => $repeatCount,
            'is_active' => true,
        ]);
    }


    /**
     * @return array{0:string,1:string} [km,en]
     */
    private function makeLevelName(string $characterType, array $charsInLevel): array
    {
        $first = $charsInLevel[0] ?? '';
        $last  = $charsInLevel[count($charsInLevel) - 1] ?? '';

        return match ($characterType) {
            'consonants' => ["{$first} - {$last}", "Characters {$first} - {$last}"],
            'digits' => ["លេខ {$first} - {$last}", "Digits {$first} - {$last}"],
            'independent_vowels' => ["ស្រៈ {$first} - {$last}", "Vowels {$first} - {$last}"],
            'dependent_vowels' => ["ស្រៈ {$first} - {$last}", "Vowels {$first} - {$last}"],
            default => ["កម្រិត", "Level"],
        };
    }

    /**
     * @return array{0:string,1:string} [km,en]
     */
    private function makeStageName(string $characterType, string $ch): array
    {
        return match ($characterType) {
            'consonants' => ["រៀនអក្សរ {$ch}", "Practice letter {$ch}"],
            'digits' => ["រៀនលេខ {$ch}", "Practice digit {$ch}"],
            'independent_vowels', 'dependent_vowels' => ["រៀនស្រៈ {$ch}", "Practice vowel {$ch}"],
            default => ["រៀន {$ch}", "Practice {$ch}"],
        };
    }

    private function buildExampleForCharacter(string $character, string $characterType): string
    {
        return match ($characterType) {
            'consonants' => "{$character} / {$character}ា / {$character}ិ / {$character}ី",
            'digits' => $character,
            'dependent_vowels', 'independent_vowels' => $character,
            default => $character,
        };
    }
}
