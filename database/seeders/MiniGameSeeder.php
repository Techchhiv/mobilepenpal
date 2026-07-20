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
                'title_kh' => 'ព្យញ្ជនៈ',
                'description' => 'Practice writing all 33 Khmer consonants against the clock!',
                'description_kh' => 'ហ្វឹកហាត់សរសេរព្យញ្ជនៈខ្មែរទាំង ៣៣ តម្រូវតាមពេលវេលាកំណត់!',
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
                'title_kh' => 'លេខ',
                'description' => 'Master Khmer digits from ០ to ៩!',
                'description_kh' => 'ស្ទាត់ជំនាញសរសេរលេខខ្មែរពី ០ ដល់ ៩!',
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
                'title_kh' => 'ស្រៈពេញតួ',
                'description' => 'Practice drawing Khmer independent vowels!',
                'description_kh' => 'ហ្វឹកហាត់គូរស្រៈពេញតួខ្មែរ!',
                'display_type' => 'character',
                'input_type' => 'drawing_board,multiple_choice,drag_and_drop',
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
                'title_kh' => 'ស្រៈនិស្ស័យ',
                'description' => 'Practice drawing Khmer dependent vowels!',
                'description_kh' => 'ហ្វឹកហាត់គូរស្រៈនិស្ស័យខ្មែរ!',
                'display_type' => 'character',
                'input_type' => 'drawing_board,multiple_choice,drag_and_drop',
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
                'title_kh' => 'រាប់លេខ',
                'description' => 'Count the objects and draw or select the correct Khmer numeral!',
                'description_kh' => 'រាប់ចំនួនវត្ថុ រួចគូរ ឬជ្រើសរើសលេខខ្មែរឱ្យបានត្រឹមត្រូវ!',
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
                'title_kh' => 'បំពេញពាក្យ',
                'description' => 'Complete the Khmer word by filling in the missing consonant!',
                'description_kh' => 'បំពេញពាក្យខ្មែរដោយបំពេញព្យញ្ជនៈដែលបាត់!',
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
                'title_kh' => 'គណិតវិទ្យា',
                'description' => 'Solve fun math equations with colorful fruits!',
                'description_kh' => 'ដោះស្រាយលំហាត់គណិតវិទ្យាដ៏រីករាយជាមួយនឹងផ្លែឈើចម្រុះពណ៌!',
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
                'title_kh' => 'សំណួរ',
                'description' => 'Read the question and solve the math puzzle!',
                'description_kh' => 'អានសំណួរ និងដោះស្រាយល្បែងគណិតវិទ្យា!',
                'display_type' => 'question',
                'input_type' => 'drawing_board,multiple_choice',
                'is_active' => true,
                'cover_image_url' => null,
                'config' => [],
            ]
        );
    }
}
