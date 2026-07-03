<?php
declare(strict_types=1);

namespace app\service;

use app\model\SiteHomeConfig;

class HomeConfigService
{
    public static function getConfigRow(): SiteHomeConfig
    {
        $row = SiteHomeConfig::find(1);
        if (!$row) {
            self::seedDefaultConfig();
            $row = SiteHomeConfig::find(1);
        }

        return $row;
    }

    public static function seedDefaultConfig(): void
    {
        SiteHomeConfig::create([
            'id'               => 1,
            'hero_subtitle_zh' => '光感美白 · 身體護理',
            'hero_subtitle_en' => 'Radiance body care',
            'hero_brand_text'  => 'CocoBrite',
            'hero_title_zh'    => '浴見光感肌',
            'hero_title_en'    => 'Glow, head to toe',
            'hero_text_zh'     => '明星單品光感美白身體乳，輕盈保濕。搭配香氛沐浴與手霜，打造每日儀式感。',
            'hero_text_en'     => 'Our hero radiance body lotion—lightweight moisture. Pair with scented bath and hand care for a daily ritual.',
            'hero_cta_zh'      => '選購身體乳',
            'hero_cta_en'      => 'Shop body lotion',
            'hero_cta_link'    => '/products',
            'hero_image'       => '/images/stock/hero.jpg',
            'updated_at'       => time(),
        ]);
    }

    /**
     * @return array<string, mixed>
     */
    public static function publicPayload(): array
    {
        $c = self::getConfigRow();

        return [
            'hero_subtitle_zh' => (string) ($c->hero_subtitle_zh ?? ''),
            'hero_subtitle_en' => (string) ($c->hero_subtitle_en ?? ''),
            'hero_brand_text'  => (string) ($c->hero_brand_text ?: 'CocoBrite'),
            'hero_title_zh'    => (string) ($c->hero_title_zh ?? ''),
            'hero_title_en'    => (string) ($c->hero_title_en ?? ''),
            'hero_text_zh'     => (string) ($c->hero_text_zh ?? ''),
            'hero_text_en'     => (string) ($c->hero_text_en ?? ''),
            'hero_cta_zh'      => (string) ($c->hero_cta_zh ?? ''),
            'hero_cta_en'      => (string) ($c->hero_cta_en ?? ''),
            'hero_cta_link'    => (string) ($c->hero_cta_link ?: '/products'),
            'hero_image'       => (string) ($c->hero_image ?? ''),
        ];
    }
}
