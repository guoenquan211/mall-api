<?php
namespace app\model;

class News extends BaseModel
{
    protected $table = 'news';
    protected $autoWriteTimestamp = true;
    protected $updateTime = false;
}
