<?php
namespace app\model;

class WithdrawalRequest extends BaseModel
{
    protected $table = 'withdrawal_requests';
    protected $autoWriteTimestamp = true;

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}
