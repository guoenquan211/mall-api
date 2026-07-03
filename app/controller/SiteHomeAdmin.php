<?php
namespace app\controller;

use app\BaseController;
use app\model\SiteHomeConfig;
use app\service\HomeConfigService;
use think\facade\Request;
use app\support\ApiLocale;

class SiteHomeAdmin extends BaseController
{
    public function getConfig()
    {
        $row = HomeConfigService::getConfigRow();

        return json(['code' => 0, 'data' => $row->toArray()]);
    }

    public function saveConfig()
    {
        $patch = Request::only([
            'hero_subtitle_zh', 'hero_subtitle_en', 'hero_brand_text',
            'hero_title_zh', 'hero_title_en', 'hero_text_zh', 'hero_text_en',
            'hero_cta_zh', 'hero_cta_en', 'hero_cta_link', 'hero_image',
        ]);
        foreach ($patch as $k => $v) {
            if ($v === null) {
                unset($patch[$k]);
            }
        }

        $row = SiteHomeConfig::find(1);
        if (!$row) {
            HomeConfigService::seedDefaultConfig();
            $row = SiteHomeConfig::find(1);
        }

        if (isset($patch['hero_cta_link'])) {
            $link = trim((string) $patch['hero_cta_link']);
            $patch['hero_cta_link'] = $link !== '' ? $link : '/products';
        }

        $patch['updated_at'] = time();
        $row->save($patch);
        $this->log('更新', '首页配置', '更新 site_home_config');

        return json(['code' => 0, 'msg' => ApiLocale::t('common.save_ok'), 'data' => HomeConfigService::publicPayload()]);
    }
}
