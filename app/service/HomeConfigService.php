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
            'hero_cta_link_type' => 'products',
            'hero_cta_link_value' => '',
            'hero_image'       => '',
            'hero_detail_show' => 0,
            'hero_detail_text_zh' => '查看詳情',
            'hero_detail_text_en' => 'View details',
            'hero_detail_link_type' => '',
            'hero_detail_link_value' => '',
            'updated_at'       => time(),
        ]);
    }

    public static function resolveLinkHref(string $type, string $val, string $legacyLink = ''): string
    {
        $type = trim($type);
        $val  = trim($val);

        if ($type === '') {
            $legacy = trim($legacyLink);
            return $legacy !== '' ? $legacy : '/products';
        }

        switch ($type) {
            case 'home_collection':
                return '#home-collection';
            case 'products':
                return '/products';
            case 'product':
                $id = (int) $val;
                return $id > 0 ? '/product/' . $id : '/products';
            case 'news':
                $id = (int) $val;
                return $id > 0 ? '/news?id=' . $id : '/news';
            case 'knowledge':
                $id = (int) $val;
                return $id > 0 ? '/knowledge?id=' . $id : '/knowledge';
            default:
                return trim($legacyLink) !== '' ? trim($legacyLink) : '/products';
        }
    }

    public static function resolveDetailHref(object $row): string
    {
        if ((int) ($row->hero_detail_show ?? 0) !== 1) {
            return '';
        }

        $type = trim((string) ($row->hero_detail_link_type ?? ''));
        $val  = trim((string) ($row->hero_detail_link_value ?? ''));
        if ($type === '' || $val === '' || !in_array($type, ['product', 'news', 'knowledge'], true)) {
            return '';
        }

        return self::resolveLinkHref($type, $val);
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
            'hero_cta_link_type' => (string) ($c->hero_cta_link_type ?? ''),
            'hero_cta_link_value' => (string) ($c->hero_cta_link_value ?? ''),
            'hero_cta_href'    => self::resolveLinkHref(
                (string) ($c->hero_cta_link_type ?? ''),
                (string) ($c->hero_cta_link_value ?? ''),
                (string) ($c->hero_cta_link ?? '/products')
            ),
            'hero_image'       => (string) ($c->hero_image ?? ''),
            'hero_detail_show' => (int) ($c->hero_detail_show ?? 0),
            'hero_detail_link_type' => (string) ($c->hero_detail_link_type ?? ''),
            'hero_detail_link_value' => (string) ($c->hero_detail_link_value ?? ''),
            'hero_detail_href' => self::resolveDetailHref($c),
        ];
    }
}
