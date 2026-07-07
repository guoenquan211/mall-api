<?php
namespace app\model;

class News extends BaseModel
{
    protected $table = 'news';
    protected $autoWriteTimestamp = true;
    protected $updateTime = false;

    /** 前台/后台表单统一使用 image，库字段为 cover_image */
    protected $append = ['image'];

    public function getImageAttr($value, $data)
    {
        return $data['cover_image'] ?? '';
    }
}
