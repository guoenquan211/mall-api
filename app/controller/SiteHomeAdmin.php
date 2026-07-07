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
            'hero_detail_show', 'hero_detail_text_zh', 'hero_detail_text_en',
            'hero_detail_link_type', 'hero_detail_link_value',
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

        if (array_key_exists('hero_detail_show', $patch)) {
            $patch['hero_detail_show'] = (int) $patch['hero_detail_show'] === 1 ? 1 : 0;
        }
        if (isset($patch['hero_detail_link_type'])) {
            $patch['hero_detail_link_type'] = trim((string) $patch['hero_detail_link_type']);
        }
        if (isset($patch['hero_detail_link_value'])) {
            $patch['hero_detail_link_value'] = trim((string) $patch['hero_detail_link_value']);
        }

        $patch['updated_at'] = time();
        $row->save($patch);
        $this->log('更新', '首页配置', '更新 site_home_config');

        return json(['code' => 0, 'msg' => ApiLocale::t('common.save_ok'), 'data' => HomeConfigService::publicPayload()]);
    }
}
