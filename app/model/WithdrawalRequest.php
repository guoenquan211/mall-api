<?php
namespace app\model;

use think\Model;

class WithdrawalRequest extends Model
{
    protected $table = 'withdrawal_requests';
    protected $autoWriteTimestamp = true;

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}
