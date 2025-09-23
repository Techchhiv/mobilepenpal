<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class Product extends Model
{
    use HasFactory;

    protected $table = 'products';

    protected $fillable = [
        'name',
        'slug',          // <-- add
        'description',
        'price',
        'category_id',
        'image',
        'status',
    ];

    protected $casts = [
        'image'  => 'array',
        'status' => 'integer', // 0/1 to match your frontend
    ];

    public function category() {
        return $this->belongsTo(Category::class);
    }

    protected static function booted()
    {
        static::saving(function (Product $product) {
            if (!$product->slug || $product->isDirty('name')) {
                $product->slug = static::makeUniqueSlug($product->name, $product->id);
            }
        });
    }

    public static function makeUniqueSlug(string $name, ?int $ignoreId = null): string
    {
        $base = Str::slug($name) ?: 'product';
        $slug = $base;
        $i = 1;

        $q = static::where('slug', $slug);
        if ($ignoreId) $q->where('id', '!=', $ignoreId);

        while ($q->exists()) {
            $slug = "{$base}-{$i}";
            $q = static::where('slug', $slug);
            if ($ignoreId) $q->where('id', '!=', $ignoreId);
            $i++;
        }
        return $slug;
    }
}
