<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Product;


class ProductShareController extends Controller
{
    //
    public function show(string $slug)
    {
        $product = Product::where('slug', $slug)->firstOrFail();

        $title = $product->name . ' — $' . number_format($product->price, 2);
        $desc  = Str::limit(strip_tags($product->description ?? ''), 160);
        $image = (is_array($product->image) && count($product->image))
            ? asset('storage/' . $product->image[0])
            : asset('assets/images/og-default.jpg');

        // Where your SPA actually lives (frontend)
        $redirect = rtrim(config('app.frontend_url', env('FRONTEND_URL', 'http://localhost:3000')), '/')
                  . '/product/' . $product->slug;

        return response()->view('share.product', compact('title','desc','image','redirect'));
    }
}
