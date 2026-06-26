<?php
namespace app\model;

class OrderItem extends BaseModel
{
    protected $table = 'order_items';
    // Items usually don't need independent timestamps if they are part of order creation, 
    // but the table definition has no timestamps.
    protected $autoWriteTimestamp = false; 
}
