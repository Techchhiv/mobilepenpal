<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

use App\Models\World;
use App\Models\Level;
use App\Models\Stage;
use App\Models\Exercise;
use App\Models\StageExercise;

use App\Models\School;
use App\Models\User;
use App\Models\SchoolWorld;

class WorldLevelStageSeeder extends Seeder
{
    /** @var array<string, \App\Models\Exercise> */
    protected array $exerciseBank = [];

    public function run()
    {
        DB::transaction(function () {
            // Clean up in FK-safe order (adjust if you have cascades)
            DB::table('stage_exercises')->delete();
            DB::table('student_exercise_attempts')->delete();
            DB::table('student_stage_progress')->delete();
            DB::table('student_level_progress')->delete();
            DB::table('student_world_progress')->delete();
            DB::table('student_sessions')->delete();
            DB::table('student_daily_stats')->delete();

            DB::table('exercises')->delete();
            DB::table('stages')->delete();
            DB::table('levels')->delete();

            // pivot must be deleted before worlds if FK exists
            DB::table('school_worlds')->delete();

            DB::table('worlds')->delete();

            // -----------------------
            // Characters
            // -----------------------
            $consonants = [
                'ក','ខ','គ','ឃ','ង','ច','ឆ','ជ','ឈ','ញ','ដ','ឋ','ឌ','ឍ','ណ','ត','ថ','ទ','ធ','ន',
                'ប','ផ','ព','ភ','ម','យ','រ','ល','វ','ស','ហ','ឡ','អ',
            ];

            $digits = ['០','១','២','៣','៤','៥','៦','៧','៨','៩'];

            $independentVowels = [
                'ឥ','ឦ','ឧ','ឩ','ឪ','ឫ','ឬ','ឭ','ឮ','ឯ','ឰ','ឱ','ឲ','ឪ'
            ];

            $dependentVowels = [
                'ា','ិ','ី','ឹ','ឺ','ុ','ូ','ួ','ើ','ឿ','ៀ','េ','ែ','ៃ','ោ','ៅ','ុំ','ំ','ាំ','ះ','ិះ','ុះ','េះ','ោះ'
            ];

            // -----------------------
            // 1) Admin public worlds (first 4)
            // audience=public => both school students + no-school users see
            // -----------------------
            $worlds = [
                [
                    'key' => 'consonants',
                    'name' => 'ព្យញ្ជនៈ',
                    'description' => 'រៀនគូរព្យញ្ជនៈខ្មែរ',
                    'theme_color' => '#4CAF50',
                    'order_index' => 1,
                    'audience' => 'public',
                    'school_id' => null,
                    'chars' => $consonants,
                    'character_type' => 'consonants',
                    'chunk' => 5,
                ],
                [
                    'key' => 'digits',
                    'name' => 'លេខ',
                    'description' => 'រៀនគូរលេខខ្មែរ',
                    'theme_color' => '#2196F3',
                    'order_index' => 2,
                    'audience' => 'public',
                    'school_id' => null,
                    'chars' => $digits,
                    'character_type' => 'digits',
                    'chunk' => 5,
                ],
                [
                    'key' => 'independent_vowels',
                    'name' => 'ស្រៈពេញតួ',
                    'description' => 'រៀនគូរស្រៈពេញតួ',
                    'theme_color' => '#FF9800',
                    'order_index' => 3,
                    'audience' => 'public',
                    'school_id' => null,
                    'chars' => $independentVowels,
                    'character_type' => 'independent_vowels',
                    'chunk' => 5,
                ],
                [
                    'key' => 'dependent_vowels',
                    'name' => 'ស្រៈនិស្ស័យ',
                    'description' => 'រៀនគូរស្រៈនិស្ស័យ',
                    'theme_color' => '#9C27B0',
                    'order_index' => 4,
                    'audience' => 'public',
                    'school_id' => null,
                    'chars' => $dependentVowels,
                    'character_type' => 'dependent_vowels',
                    'chunk' => 5,
                ],
            ];

            foreach ($worlds as $w) {
                $world = World::create([
                    'school_id'     => $w['school_id'],
                    'audience'      => $w['audience'],
                    'name'          => $w['name'],
                    'description'   => $w['description'],
                    'icon_url'      => null,
                    'map_image_url' => null,
                    'theme_color'   => $w['theme_color'],
                    'order_index'   => $w['order_index'],
                    'is_active'     => true,
                    'is_unlocked_by_default' => false,
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
                        'is_active' => true,
                        'is_unlocked_by_default' => false,
                    ]);

                    foreach ($levelChars as $stageIndex => $ch) {
                        $stageName = $this->makeStageName($w['character_type'], $ch);

                        $stage = Stage::create([
                            'level_id'    => $level->id,
                            'name'        => $stageName,
                            'description' => "Practice session for {$ch}",
                            'instruction' => "Trace {$ch} following the guided path",
                            'order_index' => $stageIndex + 1,
                            'max_stars'   => 3,
                            'is_active' => true,
                            'is_unlocked_by_default' => false,
                        ]);

                        $this->attachExerciseToStage($stage, $bank[$ch], 1, 3);
                    }
                }
            }

            // -----------------------
            // 2) Create 2 schools (+ school admin users)
            // -----------------------
            [$schoolA, $adminA] = $this->createSchoolWithAdmin(
                name: 'ITC',
                schoolKey: 'SCH-QI8AJ1',
                email: 'itc@gmail.com',
                password: 'password123'
            );

            [$schoolB, $adminB] = $this->createSchoolWithAdmin(
                name: 'Demo School B',
                schoolKey: 'SCH-DEMO-B',
                email: 'b@gmail.com',
                password: 'password123'
            );

            // -----------------------
            // 3) Admin-assigned world -> only School A has it (School B does NOT)
            // audience=assigned + pivot row for School A only
            // -----------------------
            $assignedWorld = World::create([
                'school_id'     => null,            // admin-owned
                'audience'      => 'assigned',       // only via school_worlds
                'name'          => 'Extra Practice Pack',
                'description'   => 'Admin assigned pack for selected schools',
                'icon_url'      => null,
                'map_image_url' => null,
                'theme_color'   => '#607D8B',
                'order_index'   => 999,              // not used for school stack, but keep a value
                'is_active'     => true,
                'is_unlocked_by_default' => false,
            ]);

            // Minimal content for assigned world (just a few chars)
            $assignedChars = array_slice($dependentVowels, 0, 5);
            $this->seedWorldContent(
                world: $assignedWorld,
                worldKey: 'assigned_pack',
                chars: $assignedChars,
                characterType: 'dependent_vowels',
                chunk: 5
            );

            // Assign to School A only, as first item in School A stack
            SchoolWorld::updateOrCreate(
                ['school_id' => $schoolA->id, 'world_id' => $assignedWorld->id],
                ['order_index' => 1, 'is_enabled' => true]
            );

            // -----------------------
            // 4) School-created worlds (one each)
            // school-owned => school_id set, audience can be 'assigned' (school-only)
            // and we also put them in school_worlds for ordering
            // -----------------------

            // School A creates a world (should appear AFTER assigned world in School A stack)
            $schoolAWorld = World::create([
                'school_id'     => $schoolA->id,
                'audience'      => 'assigned', // school-only (school_id enforces anyway)
                'name'          => 'School A Custom World',
                'description'   => 'Created by Demo School A',
                'icon_url'      => null,
                'map_image_url' => null,
                'theme_color'   => '#E91E63',
                'order_index'   => 1, // not used for stack ordering, but keep a value
                'is_active'     => true,
                'is_unlocked_by_default' => false,
            ]);

            $schoolAChars = array_slice($consonants, 0, 5);
            $this->seedWorldContent(
                world: $schoolAWorld,
                worldKey: 'school_a_custom',
                chars: $schoolAChars,
                characterType: 'consonants',
                chunk: 5
            );

            // Put into School A stack as #2
            SchoolWorld::updateOrCreate(
                ['school_id' => $schoolA->id, 'world_id' => $schoolAWorld->id],
                ['order_index' => 2, 'is_enabled' => true]
            );

            // School B creates a world (School B does NOT get the admin assigned world)
            $schoolBWorld = World::create([
                'school_id'     => $schoolB->id,
                'audience'      => 'assigned',
                'name'          => 'School B Custom World',
                'description'   => 'Created by Demo School B',
                'icon_url'      => null,
                'map_image_url' => null,
                'theme_color'   => '#3F51B5',
                'order_index'   => 1,
                'is_active'     => true,
                'is_unlocked_by_default' => false,
            ]);

            $schoolBChars = array_slice($digits, 0, 5);
            $this->seedWorldContent(
                world: $schoolBWorld,
                worldKey: 'school_b_custom',
                chars: $schoolBChars,
                characterType: 'digits',
                chunk: 5
            );

            // School B stack starts with its own world as #1
            SchoolWorld::updateOrCreate(
                ['school_id' => $schoolB->id, 'world_id' => $schoolBWorld->id],
                ['order_index' => 1, 'is_enabled' => true]
            );
        });
    }

    /**
     * Seed levels/stages/exercises for a given world.
     */
    private function seedWorldContent(World $world, string $worldKey, array $chars, string $characterType, int $chunk = 5): void
    {
        $bank = $this->createExerciseBank($chars, $characterType);

        $chunks = array_chunk($chars, $chunk);
        foreach ($chunks as $levelIndex => $levelChars) {
            $levelName = $this->makeLevelName($worldKey, $levelIndex, $levelChars);

            $level = Level::create([
                'world_id' => $world->id,
                'name' => $levelName,
                'description' => "Level " . ($levelIndex + 1),
                'order_index' => $levelIndex + 1,
                'background_image' => null,
                'is_active' => true,
                'is_unlocked_by_default' => false,
            ]);

            foreach ($levelChars as $stageIndex => $ch) {
                $stageName = $this->makeStageName($characterType, $ch);

                $stage = Stage::create([
                    'level_id'    => $level->id,
                    'name'        => $stageName,
                    'description' => "Practice session for {$ch}",
                    'instruction' => "Trace {$ch} following the guided path",
                    'order_index' => $stageIndex + 1,
                    'max_stars'   => 3,
                    'is_active' => true,
                    'is_unlocked_by_default' => false,
                ]);

                $this->attachExerciseToStage($stage, $bank[$ch], 1, 3);
            }
        }
    }

    /**
     * Create a school and its admin user (idempotent-ish).
     * Returns [School, User]
     */
    private function createSchoolWithAdmin(string $name, string $schoolKey, string $email, string $password): array
    {
        $school = School::updateOrCreate(
            ['school_key' => $schoolKey],
            [
                'name'        => $name,
                'slug'        => Str::slug($name),
                'admin_email' => $email,
                'is_active'   => true,
            ]
        );

        $user = User::updateOrCreate(
            ['email' => $email],
            [
                'name'      => $name . ' Admin',
                'password'  => Hash::make($password),
                'school_id' => $school->id,
            ]
        );

        // If you use spatie roles, keep this safe:
        if (method_exists($user, 'assignRole')) {
            try { $user->assignRole('school-admin'); } catch (\Throwable $e) {}
        }

        return [$school, $user];
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
                'prompt'         => "Draw: {$character}",
                'character'      => $character,
                'question'       => "Trace: {$character}",
                'options'        => json_encode([$character]),
                'instruction'    => "Follow the stroke order to draw {$character}",
                'hint'           => "Follow the guided path",
                'example'        => $this->buildExampleForCharacter($character, $characterType),
                'character_type' => $characterType,
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
            'independent_vowels' => "ស្រៈ {$first} - {$last}",
            'dependent_vowels' => "ស្រៈ {$first} - {$last}",
            default => "Level " . ($levelIndex + 1),
        };
    }

    private function makeStageName(string $characterType, string $ch): string
    {
        return match ($characterType) {
            'consonants' => "រៀនអក្សរ {$ch}",
            'digits' => "រៀនលេខ {$ch}",
            'independent_vowels', 'dependent_vowels' => "រៀនស្រៈ {$ch}",
            default => "រៀន {$ch}",
        };
    }

    private function buildExampleForCharacter(string $character, string $characterType): string
    {
        if ($characterType === 'consonants') {
            return "{$character} / {$character}ា / {$character}ិ / {$character}ី";
        }

        if ($characterType === 'digits') {
            return $character;
        }

        if ($characterType === 'dependent_vowels' || $characterType === 'independent_vowels') {
            return "{$character}";
        }

        return "{$character}";
    }
}
