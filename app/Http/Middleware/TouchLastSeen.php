<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class TouchLastSeen
{
    /**
     * Handle an incoming request.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \Closure(\Illuminate\Http\Request): (\Illuminate\Http\Response|\Illuminate\Http\RedirectResponse)  $next
     * @return \Illuminate\Http\Response|\Illuminate\Http\RedirectResponse
     */
       public function handle(Request $request, Closure $next)
    {
        if ($user = $request->user()) {
            $user->forceFill([
                'is_online'    => true,             // request with a valid token ⇒ online
                'last_seen_at' => now(),
            ])->save();

            \App\Models\Teacher::where('email', $user->email)
                ->update(['is_online' => true, 'last_seen_at' => now()]);
        }
        return $next($request);
    }
}
