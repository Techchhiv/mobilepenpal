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
        $locale = $request->header('Accept-Language');

        if ($locale && in_array($locale, ['en', 'km'])) {
            App::setLocale($locale);
        } else {
            App::setLocale('en');
        }

        return $next($request);
    }
}
