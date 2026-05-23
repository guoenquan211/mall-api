<?php
namespace app\model;

use think\Model;

class UserLog extends Model
{
    protected $table = 'user_logs';
    protected $autoWriteTimestamp = true;
}
