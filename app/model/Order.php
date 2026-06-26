<?php
namespace app\model;

class Order extends BaseModel
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
