<?php
namespace app\model;

use think\Model;

class ProductVariant extends Model
{
    protected $table = 'product_variants';
    protected $autoWriteTimestamp = true;
    protected $updateTime = false; // Based on sql, only created_at is present
}
