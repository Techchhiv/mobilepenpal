<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureSuperAdmin
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if (!$user || !$user->hasRole('super-admin')) {
            return response()->json([
                'code'    => 403,
                'message' => 'Forbidden. Super Admin access required.',
                'data'    => null,
                'errors'  => [],
            ], 403);
        }

        return $next($request);
    }
}
