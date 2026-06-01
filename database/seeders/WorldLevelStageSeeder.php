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

            $worldDefs = [
                // ===== PUBLIC WORLDS (for general/public users) =====
                [
                    'key' => 'public_consonants',
                    'audience' => 'public',
                    'order_index' => 1,
                    'name_km' => 'ព្យញ្ជនៈ',
                    'name_en' => 'Consonants',
                    'desc_km' => 'រៀនគូរព្យញ្ជនៈខ្មែរ',
                    'desc_en' => 'Learn Khmer consonants',
                    'chars' => $consonants,
                    'character_type' => 'consonants',
                    'chunk' => 5,
                    'is_unlocked_by_default' => true,
                    'is_premium' => false,
                    // 'premium_after_level' => 2,
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
                    'is_unlocked_by_default' => false,
                    'is_premium' => false,
                ],
                [
                    'key' => 'public_dependent_vowels',
                    'audience' => 'public',
                    'order_index' => 3,
                    'name_km' => 'ស្រៈនិស្ស័យ',
                    'name_en' => 'Dependent Vowels',
                    'desc_km' => 'រៀនគូរស្រៈនិស្ស័យ',
                    'desc_en' => 'Learn dependent vowels',
                    'chars' => $dependentVowels,
                    'character_type' => 'dependent_vowels',
                    'chunk' => 5,
                    'is_unlocked_by_default' => false,
                    'is_premium' => false,
                ],
                [
                    'key' => 'public_independent_vowels',
                    'audience' => 'public',
                    'order_index' => 4,
                    'name_km' => 'ស្រៈពេញតួ',
                    'name_en' => 'Independent Vowels',
                    'desc_km' => 'រៀនគូរស្រៈពេញតួ',
                    'desc_en' => 'Learn independent vowels',
                    'chars' => $independentVowels,
                    'character_type' => 'independent_vowels',
                    'chunk' => 5,
                    'is_unlocked_by_default' => false,
                    'is_premium' => false,
                ],
                // [
                //     'key' => 'public_math',
                //     'audience' => 'public',
                //     'order_index' => 5,
                //     'name_km' => 'គណិតវិទ្យា',
                //     'name_en' => 'Math',
                //     'desc_km' => 'រៀនគណិតវិទ្យា',
                //     'desc_en' => 'Learn Math',
                //     'chars' => [],
                //     'character_type' => 'math',
                //     'chunk' => 1,
                //     'is_premium' => true,
                // ],

                // ===== SCHOOL WORLDS (for school accounts) =====
                [
                    'key' => 'schools_consonants_full',
                    'audience' => 'schools',
                    'order_index' => 6,
                    'name_km' => 'ព្យញ្ជនៈ',
                    'name_en' => 'Consonants',
                    'desc_km' => 'រៀនគូរព្យញ្ជនៈខ្មែរ',
                    'desc_en' => 'Learn Khmer consonants',
                    'chars' => $consonants,
                    'character_type' => 'consonants',
                    'chunk' => 5,
                    'is_premium' => true,
                ],
                [
                    'key' => 'schools_digits',
                    'audience' => 'schools',
                    'order_index' => 7,
                    'name_km' => 'លេខ',
                    'name_en' => 'Digits',
                    'desc_km' => 'រៀនគូរលេខខ្មែរ',
                    'desc_en' => 'Learn Khmer digits',
                    'chars' => $digits,
                    'character_type' => 'digits',
                    'chunk' => 5,
                    'is_premium' => true,
                ],
                [
                    'key' => 'schools_dependent_vowels',
                    'audience' => 'schools',
                    'order_index' => 8,
                    'name_km' => 'ស្រៈនិស្ស័យ',
                    'name_en' => 'Dependent Vowels',
                    'desc_km' => 'រៀនគូរស្រៈនិស្ស័យ',
                    'desc_en' => 'Learn dependent vowels',
                    'chars' => $dependentVowels,
                    'character_type' => 'dependent_vowels',
                    'chunk' => 5,
                    'is_premium' => true,
                ],
                [
                    'key' => 'schools_independent_vowels',
                    'audience' => 'schools',
                    'order_index' => 9,
                    'name_km' => 'ស្រៈពេញតួ',
                    'name_en' => 'Independent Vowels',
                    'desc_km' => 'រៀនគូរស្រៈពេញតួ',
                    'desc_en' => 'Learn independent vowels',
                    'chars' => $independentVowels,
                    'character_type' => 'independent_vowels',
                    'chunk' => 5,
                    'is_premium' => true,
                ],
                // [
                //     'key' => 'schools_math',
                //     'audience' => 'schools',
                //     'order_index' => 10,
                //     'name_km' => 'គណិតវិទ្យា',
                //     'name_en' => 'Math',
                //     'desc_km' => 'រៀនគណិតវិទ្យា',
                //     'desc_en' => 'Learn Math',
                //     'chars' => [],
                //     'character_type' => 'math',
                //     'chunk' => 1,
                //     'is_premium' => true,
                // ],
            ];

            foreach ($worldDefs as $def) {
                $world = $this->createWorld(
                    audience: $def['audience'],
                    orderIndex: $def['order_index'],
                    nameKm: $def['name_km'],
                    nameEn: $def['name_en'],
                    descKm: $def['desc_km'],
                    descEn: $def['desc_en'],
                    unlocked: $def['is_unlocked_by_default'] ?? false,
                    isPremium: $def['is_premium'] ?? false,
                );

                $this->seedWorldContent(
                    world: $world,
                    worldKey: $def['key'],
                    chars: $def['chars'],
                    characterType: $def['character_type'],
                    chunk: $def['chunk'],
                    premiumAfterLevel: $def['premium_after_level'] ?? null,
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
        ?bool $unlocked = false,
        ?bool $isPremium = false,
    ): World {
        $data = [
            'school_id' => null,
            'audience' => $audience,
            'order_index' => $orderIndex,
            'is_active' => true,
            'is_premium' => $isPremium,
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

    private function seedWorldContent(World $world, string $worldKey, array $chars, string $characterType, int $chunk = 5, ?int $premiumAfterLevel = null): void
    {
        if ($characterType === 'math') {
            $this->seedMathWorldContent($world);
            return;
        }

        $bank = Exercise::where('character_type', $characterType)
            ->whereIn('character', $chars)
            ->get()
            ->keyBy('character');

        $chunks = array_chunk($chars, $chunk);

        foreach ($chunks as $levelIndex => $levelChars) {
            [$levelNameKm, $levelNameEn] = $this->makeLevelName($characterType, $levelChars);

            $levelNumber = $levelIndex + 1;
            $isPremiumLevel = ($premiumAfterLevel !== null && $levelNumber > $premiumAfterLevel);

            $levelData = [
                'world_id' => $world->id,
                'name' => $levelNameKm,
                'description' => "កម្រិត " . $levelNumber,
                'order_index' => $levelNumber,
                'is_active' => true,
                'is_premium' => $isPremiumLevel,
                'is_unlocked_by_default' => false,
            ];

            if (Schema::hasColumn('levels', 'name_en')) {
                $levelData['name_en'] = $levelNameEn;
            }
            if (Schema::hasColumn('levels', 'description_en')) {
                $levelData['description_en'] = "Level " . $levelNumber;
            }

            $level = Level::create($levelData);

            foreach ($levelChars as $stageIndex => $ch) {
                [$stageNameKm, $stageNameEn] = $this->makeStageName($characterType, $ch);

                $stageData = [
                    'level_id' => $level->id,
                    'name' => $stageNameKm,
                    'description' => "ហាត់សរសេរ {$ch}",
                    'order_index' => $stageIndex + 1,
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



    private function seedMathWorldContent(World $world): void
    {
        $difficulties = ['easy', 'medium', 'hard', 'very_hard'];
        $ops = ['add', 'sub', 'mul', 'div'];

        $bank = [];
        foreach ($difficulties as $diff) {
            foreach ($ops as $op) {
                $exercise = Exercise::where('character_type', 'math')
                    ->where('character', "math_{$op}_{$diff}")
                    ->first();
                if ($exercise) {
                    $bank[$diff][$op] = $exercise;
                }
            }
        }

        foreach ($ops as $i => $op) {
            [$kmName, $enName] = match ($op) {
                'add' => ['បូក', 'Addition'],
                'sub' => ['ដក', 'Subtraction'],
                'mul' => ['គុណ', 'Multiplication'],
                'div' => ['ចែក', 'Division'],
                default => [$op, ucfirst($op)],
            };

            $levelData = [
                'world_id' => $world->id,
                'name' => "ប្រមាណវិធី {$kmName}",
                'description' => "កម្រិតគណិតវិទ្យា ({$kmName})",
                'order_index' => $i + 1,
                'is_active' => true,
                'is_unlocked_by_default' => false,
            ];

            if (Schema::hasColumn('levels', 'name_en')) {
                $levelData['name_en'] = "Math - {$enName}";
            }
            if (Schema::hasColumn('levels', 'description_en')) {
                $levelData['description_en'] = "Math level ({$enName})";
            }

            $level = Level::create($levelData);

            $order = 1;
            foreach ($difficulties as $diff) {
                [$stageKmName, $stageEnName] = match ($diff) {
                    'easy' => ['ងាយ', 'Easy'],
                    'medium' => ['មធ្យម', 'Medium'],
                    'hard' => ['ពិបាក', 'Hard'],
                    'very_hard' => ['ពិបាកខ្លាំង', 'Very Hard'],
                    default => [$diff, ucfirst($diff)],
                };

                $stageData = [
                    'level_id' => $level->id,
                    'name' => "កម្រិត - {$stageKmName}",
                    'description' => "ហាត់កម្រិត {$stageKmName}",
                    'order_index' => $order++,
                    'is_active' => true,
                    'is_unlocked_by_default' => false,
                ];

                if (Schema::hasColumn('stages', 'name_en')) {
                    $stageData['name_en'] = "Difficulty - {$stageEnName}";
                }
                if (Schema::hasColumn('stages', 'description_en')) {
                    $stageData['description_en'] = "Practice {$stageEnName}";
                }

                $stage = Stage::create($stageData);

                $this->attachExerciseToStage(
                    $stage,
                    $bank[$diff][$op],
                    orderIndex: 1,
                    repeatCount: 3
                );
            }
        }
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
        $last = $charsInLevel[count($charsInLevel) - 1] ?? '';

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
}
