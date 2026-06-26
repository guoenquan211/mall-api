<?php
namespace app\model;

class Product extends BaseModel
{
    protected $table = 'products';
    // Auto timestamp
    protected $autoWriteTimestamp = true;

    protected $type = [
        'show_on_home' => 'integer',
    ];

    public function variants()
    {
        return $this->hasMany(ProductVariant::class);
    }

    public function images()
    {
        return $this->hasMany(ProductImage::class)->order('sort', 'asc');
    }
}
