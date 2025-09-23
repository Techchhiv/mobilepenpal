<?php

namespace App\Http\Controllers;

use App\Models\Category;
use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class ProductController extends Controller
{
    public function index()
    {
        return response()->json(Product::with('category')->get());
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'required',
            'price' => 'required|numeric',
            'category_id' => 'required|exists:categories,id',
            'status' => 'required|in:0,1',
            'image.*' => 'nullable|image|mimes:jpeg,png,jpg,gif,svg|max:2048',
        ]);

        $imagePaths = [];
        if ($request->hasFile('image')) {
            foreach ($request->file('image') as $image) {
                $filename = Str::uuid() . '.' . $image->getClientOriginalExtension();
                $path = $image->storeAs('products', $filename, 'public');
                $imagePaths[] = $path;
            }
        }

        $product = Product::create([
            ...$validated,
            'image' => $imagePaths,
            'category_id' => $request->category_id,

        ]);

        return response()->json($product, 201);
    }

    public function show($id)
{
    $product = Product::with('category')->find($id);

    if (!$product) {
        return response()->json(['message' => 'Product not found'], 404);
    }

    $product->increment('view_count'); // 👁️ Auto-increase view count

    return response()->json($product);
}


    public function update(Request $request, $id)
    {
        $product = Product::find($id);
        if (!$product) return response()->json(['message' => 'Product not found'], 404);

        $validated = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'description' => 'sometimes|required|string',
            'price' => 'sometimes|required|numeric',
            'category_id' => 'sometimes|required|integer',
            'status' => 'sometimes|boolean',
            'images.*' => 'nullable|image|mimes:jpeg,png,jpg,gif,svg|max:2048',
        ]);

        $imagePaths = $product->image ?? [];
        if ($request->hasFile('images')) {
            foreach ($request->file('images') as $image) {
                $filename = Str::uuid() . '.' . $image->getClientOriginalExtension();
                $path = $image->storeAs('products', $filename, 'public');
                $imagePaths[] = $path;
            }
        }

        $product->update([
            ...$validated,
            'image' => $imagePaths,
            'category_id' => $request->category_id,
        ]);

        return response()->json($product);
    }

    public function destroy($id)
    {
        $product = Product::find($id);
        if (!$product) return response()->json(['message' => 'Product not found'], 404);

        if (is_array($product->image)) {
            foreach ($product->image as $imgPath) {
                Storage::disk('public')->delete($imgPath);
            }
        }

        $product->delete();

        return response()->json(['message' => 'Product deleted successfully.']);
    }

    public function productDetailByProduct($id)
{
    $product = Product::with('category')->find($id);

    if (!$product) {
        return response()->json(['message' => 'Product not found'], 404);
    }

    return response()->json($product);
}

public function filterByCategory($categoryId)
{
    $products = Product::with('category')->where('category_id', $categoryId)->get();

    return response()->json($products);
}

public function showBySlug(string $slug)
{
    $product = Product::with('category')->where('slug', $slug)->first();
    if (!$product) return response()->json(['message' => 'Product not found'], 404);

    $product->increment('view_count');
    return response()->json($product);
}

public function filterByCategorySlug(string $slug)
{
    // If you stored Khmer slugs in `categories.slug`, this will work.
    $category = Category::where('slug', $slug)->first();

    if (!$category) {
        return response()->json([], 200);
    }

    $products = Product::with('category')
        ->where('category_id', $category->id)
        ->latest()
        ->get();

    return response()->json($products);
}


}
