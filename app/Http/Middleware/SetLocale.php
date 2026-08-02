<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\App;

class SetLocale
{
    /**
     * Handle an incoming request.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \Closure  $next
     * @return mixed
     */
    public function handle(Request $request, Closure $next)
    {
        $raw = strtolower(trim((string) $request->header('Accept-Language')));

        if ($raw !== '' && (str_contains($raw, 'km') || str_contains($raw, 'kh'))) {
            App::setLocale('km');
        } else {
            App::setLocale('en');
        }

        return $next($request);
    }
}
