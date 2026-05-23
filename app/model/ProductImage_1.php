<?php
namespace app\model;

use think\Model;

class ProductImage extends Model
{
    protected $table = 'product_images';
    protected $autoWriteTimestamp = true;
    protected $updateTime = false;
}
