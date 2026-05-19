<?php

namespace Database\Seeders;

use App\Models\MiniGame;
use Illuminate\Database\Seeder;

class MiniGameSeeder extends Seeder
{
    public function run(): void
    {
        MiniGame::truncate();

        // 1. Consonant Sprint
        MiniGame::updateOrCreate(
            ['title' => 'Consonant Sprint'],
            [
                'description' => 'Practice writing all 33 Khmer consonants against the clock!',
                'display_type' => 'character',
                'input_type' => 'drawing_board,multiple_choice,drag_and_drop',
                'is_active' => true,
                'cover_image_url' => null,
                'config' => [
                    'pool' => [
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
                    ],
                ],
            ]
        );

        // 2. Digit Sprint
        MiniGame::updateOrCreate(
            ['title' => 'Digit Sprint'],
            [
                'description' => 'Master Khmer digits from ០ to ៩!',
                'display_type' => 'character', // Changed to generic 'character'
                'input_type' => 'drawing_board,multiple_choice,drag_and_drop',
                'is_active' => true,
                'cover_image_url' => null,
                'config' => [
                    'pool' => ['០', '១', '២', '៣', '៤', '៥', '៦', '៧', '៨', '៩'],
                ],
            ]
        );

        // 3. Independent Vowel Sprint
        MiniGame::updateOrCreate(
            ['title' => 'Independent Vowel Sprint'],
            [
                'description' => 'Practice drawing Khmer independent vowels!',
                'display_type' => 'character',
                'input_type' => 'drawing_board,multiple_choice',
                'is_active' => true,
                'cover_image_url' => null,
                'config' => [
                    'pool' => [
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
                    ],
                ],
            ]
        );

        // 4. Dependent Vowel Sprint
        MiniGame::updateOrCreate(
            ['title' => 'Dependent Vowel Sprint'],
            [
                'description' => 'Practice drawing Khmer dependent vowels!',
                'display_type' => 'character',
                'input_type' => 'drawing_board,multiple_choice',
                'is_active' => true,
                'cover_image_url' => null,
                'config' => [
                    'pool' => [
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
                    ],
                ],
            ]
        );

        // 5. Counting Fun (Object Count)
        MiniGame::updateOrCreate(
            ['title' => 'Counting Fun'],
            [
                'description' => 'Count the objects and draw or select the correct Khmer numeral!',
                'display_type' => 'object_count',
                'input_type' => 'drawing_board,multiple_choice,drag_and_drop',
                'is_active' => true,
                'cover_image_url' => null,
                'config' => [
                    'pool' => ['០', '១', '២', '៣', '៤', '៥', '៦', '៧', '៨', '៩'],
                ],
            ]
        );

        // 6. Fill the Word (Missing Character)
        MiniGame::updateOrCreate(
            ['title' => 'Fill the Word'],
            [
                'description' => 'Complete the Khmer word by filling in the missing consonant!',
                'display_type' => 'missing_character',
                'input_type' => 'drawing_board,multiple_choice,drag_and_drop',
                'is_active' => true,
                'cover_image_url' => null,
                'config' => [
                    'pool' => [
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
                    ],
                ],
            ]
        );

        // 7. Math Challenge (Math Equation)
        MiniGame::updateOrCreate(
            ['title' => 'Math Challenge'],
            [
                'description' => 'Solve fun math equations with colorful fruits!',
                'display_type' => 'math_equation',
                'input_type' => 'drawing_board,multiple_choice',
                'is_active' => true,
                'cover_image_url' => null,
                'config' => [
                    'pool' => ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'],
                ],
            ]
        );

        // 8. Question (Dynamic Word Problem)
        MiniGame::updateOrCreate(
            ['title' => 'Question Time'],
            [
                'description' => 'Read the question and solve the math puzzle!',
                'display_type' => 'question',
                'input_type' => 'drawing_board,multiple_choice',
                'is_active' => true,
                'cover_image_url' => null,
                'config' => [
                    'pool' => [
                        'I have % {fruit} and {action} %. How many do I have left?',
                        'There are % {fruit} in the basket. We {action} %. What is the total now?',
                        'Anna had % {fruit} and then {action} %. How many {fruit} does she have?',
                    ],
                ],
            ]
        );
    }
}
