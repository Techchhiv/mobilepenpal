<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Laravel\Socialite\Facades\Socialite;
use Spatie\Permission\Models\Role;

class GoogleAuthController extends Controller
{
    // Frontend calls this to get Google's OAuth URL
    public function redirectToGoogle(Request $request)
    {
        $redirectAfterLogin = $request->query('redirect', '/');
        session(['redirect_after_login' => $redirectAfterLogin]);

        $url = Socialite::driver('google')->stateless()->redirect()->getTargetUrl();

        return response()->json(['url' => $url]);
    }

    // Google callback
    public function handleGoogleCallback()
    {
        try {
            $g = Socialite::driver('google')->stateless()->user();

            $user = User::updateOrCreate(
                ['email' => $g->getEmail()],
                [
                    'name'      => $g->getName() ?: Str::before($g->getEmail(), '@'),
                    'google_id' => $g->getId(),
                    'password'  => bcrypt(Str::random(40)), // not used but required
                ]
            );

            // Ensure roles exist (web guard) and make Google users "customer" by default
            Role::findOrCreate('super-admin', 'web');
            Role::findOrCreate('admin',       'web');
            Role::findOrCreate('customer',    'web');

            if (!$user->hasAnyRole(['super-admin', 'admin', 'customer'])) {
                $user->assignRole('customer'); // frontend-only
            }

            // Token for SPA
            $token = $user->createToken('spa', ['*'])->plainTextToken;

            // Where to send the browser in your React app
            $frontendUrl  = config('app.frontend_url', 'http://localhost:3000/oauth-success');
            $redirectPath = session('redirect_after_login', '/');

            return redirect()->away($frontendUrl.'?'.http_build_query([
                'token'    => $token,
                'redirect' => $redirectPath,
            ]));
        } catch (\Throwable $e) {
            $fallback = config('app.frontend_error_url', 'http://localhost:3000/sign-in');

            return redirect()->away($fallback.'?'.http_build_query([
                'error' => 'google_auth_failed',
                'msg'   => $e->getMessage(),
            ]));
        }
    }
}
