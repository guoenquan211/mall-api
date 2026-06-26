<?php
namespace app\model;

use think\Model;

/**
 * 数据库时间戳字段统一为 created_at / updated_at（与 schema_full.sql 一致）
 */
abstract class BaseModel extends Model
{
    protected $createTime = 'created_at';
    protected $updateTime = 'updated_at';
}
