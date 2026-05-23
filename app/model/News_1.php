<?php
namespace app\model;

use think\Model;

class News extends Model
{
    protected $table = 'news';
    protected $autoWriteTimestamp = true;
}
