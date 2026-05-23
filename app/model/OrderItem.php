<?php
namespace app\model;

use think\Model;

class OrderItem extends Model
{
    protected $table = 'order_items';
    // Items usually don't need independent timestamps if they are part of order creation, 
    // but the table definition has no timestamps.
    protected $autoWriteTimestamp = false; 
}
