<?php
namespace app\model;

class AffiliateProductStat extends BaseModel
{
    protected $table = 'affiliate_product_stats';

    protected $pk = ['user_id', 'product_id'];

    protected $autoWriteTimestamp = false;
}
