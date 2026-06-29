<?php
namespace app\model;

class UserAffiliateStat extends BaseModel
{
    protected $table = 'user_affiliate_stats';
    protected $pk = 'user_id';

    protected $autoWriteTimestamp = false;
}
