<?php
namespace app\model;

use think\Model;

class Order extends Model
{
    protected $table = 'orders';
    protected $autoWriteTimestamp = true;

    public function items()
    {
        return $this->hasMany(OrderItem::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
