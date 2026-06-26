<?php
namespace app\model;

class AdminLog extends BaseModel
{
    protected $table = 'admin_logs';
    protected $autoWriteTimestamp = true;
    protected $updateTime = false; // logs are immutable usually
}
