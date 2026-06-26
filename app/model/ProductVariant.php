<?php
namespace app\model;

class ProductVariant extends BaseModel
{
    protected $table = 'product_variants';
    protected $autoWriteTimestamp = true;
    protected $updateTime = false; // Based on sql, only created_at is present
}
