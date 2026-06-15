<?php

namespace Database\Seeders;

use App\Models\QuestionTemplate;
use Illuminate\Database\Seeder;

class QuestionTemplateSeeder extends Seeder
{
    public function run(): void
    {
        QuestionTemplate::truncate();

        $templates = [
            // ── Addition (add) ──────────────────────────────────────
            [
                'question_en' => 'I have {a} {fruit} and get {b} more. How many do I have now?',
                'question_kh' => 'ខ្ញុំមាន {fruit} {a} ហើយទទួលបាន {b} ទៀត។ តើឥឡូវខ្ញុំមានប៉ុន្មាន?',
                'operation' => 'add',
                'difficulty' => 'easy',
            ],
            [
                'question_en' => 'There are {a} {fruit} on the table. Mom puts {b} more. How many {fruit} are there?',
                'question_kh' => 'មាន {fruit} {a} នៅលើតុ។ ម៉ាក់ដាក់ {b} ទៀត។ តើមាន {fruit} ប៉ុន្មាន?',
                'operation' => 'add',
                'difficulty' => 'easy',
            ],
            [
                'question_en' => '{a} birds sit on a tree. {b} more fly in. How many birds are there now?',
                'question_kh' => 'សត្វបក្សី {a} ជំនួតលើដើមឈើ។ មាន {b} ទៀតហើរមក។ តើមានសត្វបក្សីប៉ុន្មានឥឡូវ?',
                'operation' => 'add',
                'difficulty' => 'easy',
            ],
            [
                'question_en' => 'Anna has {a} stickers. Her friend gives her {b} more. How many stickers does Anna have?',
                'question_kh' => 'អាណា មានស្ទីកឃ័រ {a}។ មិត្តរបស់នាងឱ្យ {b} ទៀត។ តើអាណា មានស្ទីកឃ័រប៉ុន្មាន?',
                'operation' => 'add',
                'difficulty' => 'easy',
            ],

            // ── Subtraction (sub) ───────────────────────────────────
            [
                'question_en' => 'I have {a} {fruit} and eat {b}. How many are left?',
                'question_kh' => 'ខ្ញុំមាន {fruit} {a} ហើយបរិភោគ {b}។ តើនៅសល់ប៉ុន្មាន?',
                'operation' => 'sub',
                'difficulty' => 'easy',
            ],
            [
                'question_en' => 'There are {a} {fruit} in a basket. We take out {b}. How many are left?',
                'question_kh' => 'មាន {fruit} {a} នៅក្នុងកញ្ច្រែង។ យើងយក {b} ចេញ។ តើនៅសល់ប៉ុន្មាន?',
                'operation' => 'sub',
                'difficulty' => 'easy',
            ],
            [
                'question_en' => 'Dara had {a} balloons. {b} flew away. How many does he have now?',
                'question_kh' => 'តារា មានបាឡុង {a}។ {b} ហើរបាត់។ តើគេមានប៉ុន្មានឥឡូវ?',
                'operation' => 'sub',
                'difficulty' => 'easy',
            ],
            [
                'question_en' => 'A hen has {a} eggs. {b} eggs hatch. How many eggs are left?',
                'question_kh' => 'មាន់មានស៊ុត {a}។ ស៊ុត {b} បានកើត។ តើស៊ុតនៅសល់ប៉ុន្មាន?',
                'operation' => 'sub',
                'difficulty' => 'easy',
            ],

            // ── Multiplication (mul) ────────────────────────────────
            [
                'question_en' => 'There are {a} boxes. Each box has {b} {fruit}. How many {fruit} are there in total?',
                'question_kh' => 'មានប្រអប់ {a}។ ប្រអប់នីមួយៗមាន {fruit} {b}។ តើមាន {fruit} ប៉ុន្មានសរុប?',
                'operation' => 'mul',
                'difficulty' => 'medium',
            ],
            [
                'question_en' => '{a} children each have {b} pencils. How many pencils are there in total?',
                'question_kh' => 'កុមារ {a} នាក់ នាក់នីមួយមានខ្មៅដៃ {b}។ តើមានខ្មៅដៃប៉ុន្មានសរុប?',
                'operation' => 'mul',
                'difficulty' => 'medium',
            ],
            [
                'question_en' => 'Mom buys {a} bags of {fruit}. Each bag has {b} inside. How many {fruit} did she buy?',
                'question_kh' => 'ម៉ាក់ទិញថង់ {fruit} {a}។ ថង់នីមួយមាន {b} នៅខាងក្នុង។ តើម៉ាក់ទិញ {fruit} ប៉ុន្មាន?',
                'operation' => 'mul',
                'difficulty' => 'medium',
            ],

            // ── Division (div) ──────────────────────────────────────
            [
                'question_en' => 'We have {a} {fruit} to share equally among {b} friends. How many does each friend get?',
                'question_kh' => 'យើងមាន {fruit} {a} ដើម្បីចែកស្មើគ្នាក្នុងចំណោមមិត្ត {b} នាក់។ តើមិត្តម្នាក់ៗទទួលបានប៉ុន្មាន?',
                'operation' => 'div',
                'difficulty' => 'medium',
            ],
            [
                'question_en' => 'A teacher has {a} stickers to give equally to {b} students. How many stickers does each student get?',
                'question_kh' => 'គ្រូមានស្ទីកឃ័រ {a} ដើម្បីចែកស្មើគ្នាដល់សិស្ស {b} នាក់។ តើសិស្សម្នាក់ៗទទួលបានស្ទីកឃ័រប៉ុន្មាន?',
                'operation' => 'div',
                'difficulty' => 'medium',
            ],
            [
                'question_en' => '{a} cookies are put into {b} jars equally. How many cookies are in each jar?',
                'question_kh' => 'នំ {a} ត្រូវបានដាក់ក្នុងក្រឡ {b} ស្មើៗគ្នា។ តើក្រឡមួយមាននំប៉ុន្មាន?',
                'operation' => 'div',
                'difficulty' => 'medium',
            ],

            // ── Harder templates ─────────────────────────────────────
            [
                'question_en' => 'I have {a} {fruit}. My friend gives me {b} more. Then I eat 1. How many are left?',
                'question_kh' => 'ខ្ញុំមាន {fruit} {a}។ មិត្តខ្ញុំឱ្យ {b} ទៀត។ បន្ទាប់មកខ្ញុំបរិភោគ ១។ តើនៅសល់ប៉ុន្មាន?',
                'operation' => 'add',
                'difficulty' => 'hard',
            ],
        ];

        foreach ($templates as $template) {
            QuestionTemplate::create(array_merge($template, ['is_active' => true]));
        }
    }
}
