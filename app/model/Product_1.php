<?php
namespace app\model;

use think\Model;

class Product extends Model
{
    protected $table = 'products';
    // Auto timestamp
    protected $autoWriteTimestamp = true;

    public function variants()
    {
        return $this->hasMany(ProductVariant::class);
    }

    public function images()
    {
        return $this->hasMany(ProductImage::class)->order('sort', 'asc');
    }
}
