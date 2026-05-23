<?php
namespace app\model;

use think\Model;

class AdminLog extends Model
{
    protected $table = 'admin_logs';
    protected $autoWriteTimestamp = true;
    protected $updateTime = false; // logs are immutable usually
}
