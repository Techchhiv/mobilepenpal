<?php

namespace App\Helpers;

use Carbon\Carbon;
use App\Models\StudentExerciseAttempt;
use App\Models\StudentDailyStat;
use Illuminate\Support\Collection;

class StudentSummary
{
    public static function getDailySummary(int $studentId, $date): array
    {
        $date = Carbon::parse($date)->toDateString();

        /** @var StudentDailyStat|null $stat */
        $stat = StudentDailyStat::forStudent($studentId)
            ->forDate($date)
            ->first();

        $exercisesAttempted = $stat?->exercises_attempted ?? 0;
        $correctAttempts = $stat?->correct_attempts ?? 0;
        $timeSpentSeconds = $stat?->time_spent_seconds ?? 0;

        $accuracy = $exercisesAttempted > 0
            ? round($correctAttempts / $exercisesAttempted, 2)
            : 0.0;

        $attempts = StudentExerciseAttempt::with('exercise.stages')
            ->forStudent($studentId)
            ->forDate($date)
            ->get();

        $characterGroups = $attempts
            ->groupBy(function ($attempt) {
                return optional($attempt->exercise)->character;
            })
            ->filter();

        $characters = $characterGroups->map(function ($group, $character) {
            $attemptsCount = $group->count();
            $correctCount  = $group->where('is_correct', true)->count();
            $charAccuracy  = $attemptsCount > 0
                ? round($correctCount / $attemptsCount, 2)
                : 0.0;

            return [
                'character' => $character,
                'attempts' => $attemptsCount,
                'correct_attempts' => $correctCount,
                'accuracy' => $charAccuracy,
            ];
        })->values();

        $best = null;
        $needsAttention = null;

        foreach ($characters as $c) {
            if ($c['attempts'] < 2) {
                continue;
            }

            if (!$best || $c['accuracy'] > $best['accuracy']) {
                $best = [
                    'character' => $c['character'],
                    'accuracy' => $c['accuracy'],
                ];
            }

            if (!$needsAttention || $c['accuracy'] < $needsAttention['accuracy']) {
                $needsAttention = [
                    'character' => $c['character'],
                    'accuracy' => $c['accuracy'],
                ];
            }
        }

        if ($best && $needsAttention && $best['accuracy'] === $needsAttention['accuracy']) {
            $needsAttention = null;
        }

        $stageGroups = $attempts
            ->groupBy(function ($attempt) {
                $stage = optional($attempt->exercise)->stages->first();
                return optional($stage)->id;
            })
            ->filter();

        $starsEarned = 0;
        $stagesCompleted = 0;

        foreach ($stageGroups as $stageId => $group) {
            $stage = optional($group->first()->exercise)->stages->first();
            if (!$stage) {
                continue;
            }

            $attemptsCount = $group->count();
            $correctCount  = $group->where('is_correct', true)->count();
            $score = $attemptsCount > 0
                ? ($correctCount / $attemptsCount) * 100
                : 0;

            $sessionStars = self::calculateSessionStars($score, (int) $stage->max_stars);
            $starsEarned += $sessionStars;

            if ($score >= 50) {
                $stagesCompleted++;
            }
        }

        return [
            'student_id' => $studentId,
            'date' => $date,

            'stars_earned' => $starsEarned,
            'stages_completed' => $stagesCompleted,
            'time_spent_seconds'  => $timeSpentSeconds,

            'exercises_attempted' => $exercisesAttempted,
            'correct_attempts' => $correctAttempts,
            'accuracy' => $accuracy,

            'characters_practiced' => $characters,
            'best_character' => $best,
            'needs_attention' => $needsAttention,
        ];
    }

    private static function calculateSessionStars(float $score, int $maxStars): int
    {
        if ($score === 100.0) {
            return $maxStars;
        }

        if ($score >= 50.0) {
            return 2;
        }

        return 1;
    }



    public static function getWeeklySummary(int $studentId, $fromDate, $toDate): array
    {
        $from = Carbon::parse($fromDate)->startOfDay();
        $to = Carbon::parse($toDate)->endOfDay();

        $fromDateStr = $from->toDateString();
        $toDateStr = $to->toDateString();

        $aggregated = StudentDailyStat::forStudent($studentId)
            ->betweenDates($fromDateStr, $toDateStr)
            ->selectRaw('
            COALESCE(SUM(exercises_attempted), 0) as total_exercises_attempted,
            COALESCE(SUM(correct_attempts), 0) as total_correct_attempts,
            COALESCE(SUM(time_spent_seconds), 0) as total_time_spent_seconds,
            COUNT(*) as practice_days
        ')
            ->first();

        $totalAttempts   = (int) ($aggregated->total_exercises_attempted ?? 0);
        $totalCorrect    = (int) ($aggregated->total_correct_attempts ?? 0);
        $totalTimeSpent  = (int) ($aggregated->total_time_spent_seconds ?? 0);
        $practiceDays    = (int) ($aggregated->practice_days ?? 0);

        $accuracy = $totalAttempts > 0
            ? round($totalCorrect / $totalAttempts, 2)
            : 0.0;

        $attempts = StudentExerciseAttempt::with('exercise.stages')
            ->where('student_id', $studentId)
            ->whereBetween('created_at', [$from, $to])
            ->get();

        $characterGroups = $attempts
            ->groupBy(function ($attempt) {
                return optional($attempt->exercise)->character;
            })
            ->filter();

        $characters = $characterGroups->map(function ($group, $character) {
            $attemptsCount = $group->count();
            $correctCount  = $group->where('is_correct', true)->count();
            $charAccuracy  = $attemptsCount > 0
                ? round($correctCount / $attemptsCount, 2)
                : 0.0;

            return [
                'character' => $character,
                'attempts' => $attemptsCount,
                'correct_attempts' => $correctCount,
                'accuracy' => $charAccuracy,
            ];
        })->values();

        $charactersAttempted = $characters->count();

        $topMastered = [];
        $needsReview = [];

        foreach ($characters as $c) {
            if ($c['attempts'] < 3) {
                continue;
            }

            if ($c['accuracy'] >= 0.80) {
                $topMastered[] = [
                    'character' => $c['character'],
                    'accuracy' => $c['accuracy'],
                ];
            }

            if ($c['accuracy'] <= 0.50) {
                $needsReview[] = [
                    'character' => $c['character'],
                    'accuracy' => $c['accuracy'],
                ];
            }
        }

        $stageGroups = $attempts
            ->groupBy(function ($attempt) {
                $stage = optional($attempt->exercise)->stages->first();
                return optional($stage)->id;
            })
            ->filter();

        $totalStarsEarned     = 0;
        $totalStagesCompleted = 0;

        foreach ($stageGroups as $stageId => $group) {
            $stage = optional($group->first()->exercise)->stages->first();
            if (!$stage) continue;

            $attemptsCount = $group->count();
            $correctCount  = $group->where('is_correct', true)->count();
            $score         = $attemptsCount > 0
                ? ($correctCount / $attemptsCount) * 100
                : 0;

            $sessionStars = self::calculateSessionStars($score, (int) $stage->max_stars);
            $totalStarsEarned += $sessionStars;

            if ($score >= 50) {
                $totalStagesCompleted++;
            }
        }

        return [
            'student_id' => $studentId,
            'from_date' => $fromDateStr,
            'to_date' => $toDateStr,

            'total_stars_earned' => $totalStarsEarned,
            'total_stages_completed' => $totalStagesCompleted,
            'total_time_spent_seconds' => $totalTimeSpent,

            'total_exercises_attempted' => $totalAttempts,
            'total_correct_attempts' => $totalCorrect,
            'accuracy' => $accuracy,

            'practice_days' => $practiceDays,
            'characters_attempted' => $charactersAttempted,
            'characters_summary' => $characters,

            'top_mastered_characters' => $topMastered,
            'characters_to_review' => $needsReview,
        ];
    }

    public static function getMonthlySummary(int $studentId, ?string $month = null): array
    {
        [$from, $to, $monthStr] = self::parseMonthRange($month);

        $totals = self::monthlyTotals($studentId, $from, $to);
        $weeklyChart = self::monthlyWeeklyChart($studentId, $from, $to);
        $attempts = self::monthlyAttempts($studentId, $from, $to);

        $charactersSummary = self::characterSummaryFromAttempts($attempts);
        [$topMastered, $toReview] = self::characterInsights($charactersSummary);

        [$starsEarned, $stagesCompleted] = self::stageStarsFromAttempts($attempts);

        return [
            'student_id' => $studentId,

            'month'     => $monthStr,
            'from_date' => $from->toDateString(),
            'to_date'   => $to->toDateString(),

            'total_stars_earned'        => $starsEarned,
            'total_stages_completed'    => $stagesCompleted,
            'total_time_spent_seconds'  => $totals['total_time_spent_seconds'],

            'total_exercises_attempted' => $totals['total_exercises_attempted'],
            'total_correct_attempts'    => $totals['total_correct_attempts'],
            'accuracy'                  => $totals['accuracy'],
            'practice_days'             => $totals['practice_days'],

            'weekly_chart' => $weeklyChart,
            'characters_summary'        => $charactersSummary,
            'top_mastered_characters'   => $topMastered,
            'characters_to_review'      => $toReview,
        ];
    }

    private static function parseMonthRange(?string $month): array
    {
        $monthStr = $month ?: Carbon::now()->format('Y-m');
        $from = Carbon::createFromFormat('Y-m', $monthStr)->startOfMonth();
        $to = $from->copy()->endOfMonth();
        return [$from, $to, $monthStr];
    }

    private static function monthlyTotals(int $studentId, Carbon $from, Carbon $to): array
    {
        $row = StudentDailyStat::forStudent($studentId)
            ->betweenDates($from->toDateString(), $to->toDateString())
            ->selectRaw('
                COALESCE(SUM(exercises_attempted), 0) as total_exercises_attempted,
                COALESCE(SUM(correct_attempts), 0) as total_correct_attempts,
                COALESCE(SUM(time_spent_seconds), 0) as total_time_spent_seconds,
                COUNT(*) as practice_days
            ')
            ->first();

        $attempts = (int) ($row->total_exercises_attempted ?? 0);
        $correct  = (int) ($row->total_correct_attempts ?? 0);

        return [
            'total_exercises_attempted' => $attempts,
            'total_correct_attempts'    => $correct,
            'total_time_spent_seconds'  => (int) ($row->total_time_spent_seconds ?? 0),
            'practice_days'             => (int) ($row->practice_days ?? 0),
            'accuracy'                  => $attempts > 0 ? round($correct / $attempts, 2) : 0.0,
        ];
    }

    private static function monthlyWeeklyChart(int $studentId, Carbon $from, Carbon $to): array
    {
        /** @var Collection<string, StudentDailyStat> $byDate */
        $byDate = StudentDailyStat::forStudent($studentId)
            ->betweenDates($from->toDateString(), $to->toDateString())
            ->get()
            ->keyBy(fn($r) => Carbon::parse($r->date)->toDateString());

        $weeks = [];

        $cursor = $from->copy()->startOfMonth();
        $end = $to->copy()->endOfMonth();

        $weekIndex = 1;

        while ($cursor->lte($end)) {
            $weekStart = $cursor->copy();
            $weekEnd = $cursor->copy()->addDays(6);

            if ($weekEnd->gt($end)) {
                $weekEnd = $end->copy();
            }

            $sumAttempts = 0;
            $sumCorrect = 0;
            $sumTime = 0;

            $d = $weekStart->copy();
            while ($d->lte($weekEnd)) {
                $key = $d->toDateString();
                $row = $byDate->get($key);

                $attempts = (int) ($row->exercises_attempted ?? 0);
                $correct  = (int) ($row->correct_attempts ?? 0);

                $sumAttempts += $attempts;
                $sumCorrect  += $correct;
                $sumTime     += (int) ($row->time_spent_seconds ?? 0);

                $d->addDay();
            }

            $accuracy = $sumAttempts > 0 ? round($sumCorrect / $sumAttempts, 2) : 0.0;

            $weeks[] = [
                'week'              => $weekIndex,
                'from_date'         => $weekStart->toDateString(),
                'to_date'           => $weekEnd->toDateString(),
                'attempts'          => $sumAttempts,
                'time_spent_seconds' => $sumTime,
                'accuracy'          => $accuracy,
            ];

            $weekIndex++;
            $cursor = $weekEnd->copy()->addDay();
        }

        return $weeks;
    }


    private static function monthlyAttempts(int $studentId, Carbon $from, Carbon $to): Collection
    {
        return StudentExerciseAttempt::with('exercise.stages')
            ->where('student_id', $studentId)
            ->whereBetween('created_at', [$from->copy()->startOfDay(), $to->copy()->endOfDay()])
            ->get();
    }

    private static function characterSummaryFromAttempts(Collection $attempts): array
    {
        $groups = $attempts
            ->groupBy(fn($a) => optional($a->exercise)->character)
            ->filter();

        return $groups->map(function ($group, $character) {
            $count = $group->count();
            $correct = $group->where('is_correct', true)->count();

            return [
                'character'        => (string) $character,
                'attempts'         => (int) $count,
                'correct_attempts' => (int) $correct,
                'accuracy'         => $count > 0 ? round($correct / $count, 2) : 0.0,
            ];
        })->values()->all();
    }

    private static function characterInsights(array $charactersSummary): array
    {
        $top = [];
        $review = [];

        foreach ($charactersSummary as $c) {
            if (($c['attempts'] ?? 0) < 3) continue;

            if (($c['accuracy'] ?? 0) >= 0.80) {
                $top[] = ['character' => $c['character'], 'accuracy' => $c['accuracy']];
            }
            if (($c['accuracy'] ?? 0) <= 0.50) {
                $review[] = ['character' => $c['character'], 'accuracy' => $c['accuracy']];
            }
        }

        $top = collect($top)->sortByDesc('accuracy')->take(5)->values()->all();
        $review = collect($review)->sortBy('accuracy')->take(5)->values()->all();

        return [$top, $review];
    }

    private static function stageStarsFromAttempts(Collection $attempts): array
    {
        $totalStarsEarned = 0;
        $totalStagesCompleted = 0;

        $stageGroups = $attempts
            ->groupBy(function ($attempt) {
                $stage = optional($attempt->exercise)->stages->first();
                return optional($stage)->id;
            })
            ->filter();

        foreach ($stageGroups as $group) {
            $stage = optional($group->first()->exercise)->stages->first();
            if (!$stage) continue;

            $count = $group->count();
            $correct = $group->where('is_correct', true)->count();
            $score = $count > 0 ? ($correct / $count) * 100 : 0;

            $totalStarsEarned += self::calculateSessionStars($score, (int) $stage->max_stars);
            if ($score >= 50) $totalStagesCompleted++;
        }

        return [$totalStarsEarned, $totalStagesCompleted];
    }
}
