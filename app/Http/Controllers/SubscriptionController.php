<?php

namespace App\Http\Controllers;

use App\Models\Subscription;
use App\Models\School;
use Illuminate\Http\Request;

class SubscriptionController extends Controller
{
    public function __construct()
    {
        $this->middleware(['auth:api', 'role:super-admin,api']);
    }

    
    public function index(School $school)
    {
        return response()->json($school->subscriptions()->latest()->get());
    }

    public function store(Request $request, School $school)
    {
        $request->validate([
            'plan'   => 'required|in:monthly,yearly',
            'amount' => 'required|numeric|min:0',
        ]);

        $start = now();
        $end   = $request->plan === 'monthly'
            ? $start->copy()->addMonth()
            : $start->copy()->addYear();

        $subscription = $school->subscriptions()->create([
            'plan'       => $request->plan,
            'amount'     => $request->amount,
            'start_date' => $start,
            'end_date'   => $end,
            'active'     => true,
        ]);

        return response()->json([
            'message'       => 'Subscription created successfully',
            'subscription'  => $subscription,
        ], 201);
    }
}
