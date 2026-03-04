<?php

namespace App\Http\Controllers\Admin\V01;

use App\Http\Controllers\Controller;
use App\Models\School;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    public function index(Request $request)
    {
        $totalSchools = School::count();
        $activeSchools = School::where('is_active', true)->count();
        $totalStudents = DB::table('students')->count();
        $totalTeachers = DB::table('teachers')->count();

        $topSchools = School::withCount(['students', 'teachers'])
            ->orderBy('students_count', 'desc')
            ->take(5)
            ->get();

        return response()->json([
            'success' => true,
            'data' => [
                'summary' => [
                    'total_schools' => $totalSchools,
                    'active_schools' => $activeSchools,
                    'total_students' => $totalStudents,
                    'total_teachers' => $totalTeachers,
                ],
                'top_schools' => $topSchools
            ]
        ]);
    }
}
