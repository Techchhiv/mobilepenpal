<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\ProfileController;
use Illuminate\Foundation\Application;
use Illuminate\Support\Facades\Route;
use Inertia\Inertia;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| contains the "web" middleware group. Now create something great!
|
*/

Route::get('/', function () {
    return Inertia::render('Welcome', [
        'canLogin' => Route::has('login'),
        'canRegister' => Route::has('register'),
        'laravelVersion' => Application::VERSION,
        'phpVersion' => PHP_VERSION,
    ]);
});


Route::get('/dashboard', function () {
    return Inertia::render('Dashboard');
})->middleware(['auth', 'verified'])->name('dashboard');

// Route::view('/{any}', 'index')->where('any', '.*');
Route::view('/{any}', 'index')->where('any', '^(?!api|sanctum/csrf-cookie|storage).*');

Route::get('/p/{slug}', function (string $slug) {
    $p = Product::where('slug', $slug)->firstOrFail();

    $title = $p->name;
    $desc  = \Str::limit(strip_tags($p->description ?? ''), 160);
    $img   = $p->image[0] ?? null;
    $imgUrl = $img ? asset('storage/' . ltrim($img, '/')) : asset('images/default-og.jpg');

    $frontend = rtrim(config('app.frontend_url', 'http://localhost:3000'), '/');

    return response()->view('share', [
        'title'   => $title,
        'desc'    => $desc,
        'imgUrl'  => $imgUrl,
        'pageUrl' => url()->current(),
        'redirectUrl' => $frontend . '/product/' . $p->slug,
    ]);
});





Route::middleware('auth')->group(function () {
    Route::get('/profile', [ProfileController::class, 'edit'])->name('profile.edit');
    Route::patch('/profile', [ProfileController::class, 'update'])->name('profile.update');
    Route::delete('/profile', [ProfileController::class, 'destroy'])->name('profile.destroy');
});

require __DIR__ . '/auth.php';
