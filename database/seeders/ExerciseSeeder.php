<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use App\Models\Exercise;
use Illuminate\Support\Facades\Schema;

class ExerciseSeeder extends Seeder
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

            $this->createExerciseBank($consonants, 'consonants');
            $this->createExerciseBank($digits, 'digits');
            $this->createExerciseBank($independentVowels, 'independent_vowels');
            $this->createExerciseBank($dependentVowels, 'dependent_vowels');

            $difficulties = ['easy', 'medium', 'hard', 'very_hard'];
            $ops = ['add', 'sub', 'mul', 'div'];
            $this->createMathExerciseBank($difficulties, $ops);
        });
    }

    private function cleanup(): void
    {
        if (Schema::hasTable('exercises')) {
            Schema::disableForeignKeyConstraints();
            DB::table('exercises')->delete();
            Schema::enableForeignKeyConstraints();
        }
    }

    private function createExerciseBank(array $characters, string $characterType): void
    {
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
            } else {
                Exercise::create([
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
    }

    private function createMathExerciseBank(array $difficulties, array $ops): void
    {
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

                Exercise::updateOrCreate(
                    [
                        'character' => $characterKey,
                        'character_type' => 'math',
                    ],
                    $data
                );
            }
        }
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
