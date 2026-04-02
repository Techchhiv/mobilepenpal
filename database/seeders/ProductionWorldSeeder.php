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

class ProductionWorldSeeder extends Seeder
{
    public function run(): void
    {
        DB::transaction(function () {
            // -----------------------
            // Characters (Extract 10 for each to have 2 levels of 5 stages)
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
            ]; // Exactly 10

            $digits = [
                '០',
                '១',
                '២',
                '៣',
                '៤',
                '៥',
                '៦',
                '៧',
                '៨',
                '៩'
            ]; // Exactly 10

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
            ]; // Exactly 10

            $worldDefs = [
                [
                    'key' => 'prod_consonants',
                    'audience' => 'public',
                    'order_index' => 1,
                    'name_km' => 'ព្យញ្ជនៈ',
                    'name_en' => 'Consonants',
                    'desc_km' => 'រៀនគូរព្យញ្ជនៈខ្មែរ',
                    'desc_en' => 'Learn Khmer consonants',
                    'chars' => $consonants,
                    'character_type' => 'consonants',
                    'chunk' => 5, // 5 stages per level
                    'is_unlocked_by_default' => true,
                    'is_premium' => false,
                ],
                [
                    'key' => 'prod_digits',
                    'audience' => 'public',
                    'order_index' => 2,
                    'name_km' => 'លេខ',
                    'name_en' => 'Digits',
                    'desc_km' => 'រៀនគូរលេខខ្មែរ',
                    'desc_en' => 'Learn Khmer digits',
                    'chars' => $digits,
                    'character_type' => 'digits',
                    'chunk' => 5, // 5 stages per level
                    'is_unlocked_by_default' => false,
                    'is_premium' => false,
                ],
                [
                    'key' => 'prod_dependent_vowels',
                    'audience' => 'public',
                    'order_index' => 3,
                    'name_km' => 'ស្រៈនិស្ស័យ',
                    'name_en' => 'Dependent Vowels',
                    'desc_km' => 'រៀនគូរស្រៈនិស្ស័យ',
                    'desc_en' => 'Learn dependent vowels',
                    'chars' => $dependentVowels,
                    'character_type' => 'dependent_vowels',
                    'chunk' => 5, // 5 stages per level
                    'is_unlocked_by_default' => false,
                    'is_premium' => false,
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

                if (isset($bank[$ch])) {
                    $this->attachExerciseToStage($stage, $bank[$ch], 1, 3);
                }
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
