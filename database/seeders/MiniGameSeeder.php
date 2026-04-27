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
                'input_type' => 'drawing_board,multiple_choice',
                'is_active' => true,
                'cover_image_url' => null,
                'config' => [
                    'pool' => [
                        'ក', 'ខ', 'គ', 'ឃ', 'ង',
                        'ច', 'ឆ', 'ជ', 'ឈ', 'ញ',
                        'ដ', 'ឋ', 'ឌ', 'ឍ', 'ណ',
                        'ត', 'ថ', 'ទ', 'ធ', 'ន',
                        'ប', 'ផ', 'ព', 'ភ', 'ម',
                        'យ', 'រ', 'ល', 'វ', 'ស',
                        'ហ', 'ឡ', 'អ',
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
                'input_type' => 'drawing_board,multiple_choice',
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
                        'ឥ', 'ឦ', 'ឧ', 'ឩ', 'ឪ', 'ឫ', 'ឬ', 'ឭ', 'ឮ', 'ឯ', 'ឰ', 'ឱ', 'ឲ', 'ឪ'
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
                        'ា', 'ិ', 'ី', 'ឹ', 'ឺ', 'ុ', 'ូ', 'ួ', 'ើ', 'ឿ', 'ៀ', 'េ', 'ែ', 'ៃ', 'ោ', 'ៅ', 'ុំ', 'ំ', 'ាំ', 'ះ', 'ិះ', 'ុះ', 'េះ', 'ោះ'
                    ],
                ],
            ]
        );
    }
}
