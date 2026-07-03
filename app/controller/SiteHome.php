<?php
namespace app\controller;

use app\BaseController;
use app\service\HomeConfigService;

class SiteHome extends BaseController
{
    /** 前台：首页 Hero 配置 */
    public function publicConfig()
    {
        return json(['code' => 0, 'data' => HomeConfigService::publicPayload()]);
    }
}
