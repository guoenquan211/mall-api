-- 首页 Hero 区块配置（可重复执行）

SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS `site_home_config` (
  `id` tinyint(3) unsigned NOT NULL DEFAULT '1',
  `hero_subtitle_zh` varchar(200) DEFAULT NULL COMMENT '竖排副标题(繁)',
  `hero_subtitle_en` varchar(200) DEFAULT NULL COMMENT '竖排副标题(英)',
  `hero_brand_text` varchar(100) NOT NULL DEFAULT 'CocoBrite' COMMENT '竖排品牌大字',
  `hero_title_zh` varchar(200) DEFAULT NULL COMMENT '主标题(繁)',
  `hero_title_en` varchar(200) DEFAULT NULL COMMENT '主标题(英)',
  `hero_text_zh` text COMMENT '描述(繁)',
  `hero_text_en` text COMMENT '描述(英)',
  `hero_cta_zh` varchar(100) DEFAULT NULL COMMENT '按钮文字(繁)',
  `hero_cta_en` varchar(100) DEFAULT NULL COMMENT '按钮文字(英)',
  `hero_cta_link` varchar(255) NOT NULL DEFAULT '/products' COMMENT '按钮链接',
  `hero_image` varchar(512) DEFAULT NULL COMMENT '右侧大图',
  `updated_at` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='首页Hero配置(单行)';

INSERT INTO `site_home_config` (
  `id`, `hero_subtitle_zh`, `hero_subtitle_en`, `hero_brand_text`,
  `hero_title_zh`, `hero_title_en`, `hero_text_zh`, `hero_text_en`,
  `hero_cta_zh`, `hero_cta_en`, `hero_cta_link`, `hero_image`, `updated_at`
) VALUES (
  1,
  '光感美白 · 身體護理',
  'Radiance body care',
  'CocoBrite',
  '浴見光感肌',
  'Glow, head to toe',
  '明星單品光感美白身體乳，輕盈保濕。搭配香氛沐浴與手霜，打造每日儀式感。',
  'Our hero radiance body lotion—lightweight moisture. Pair with scented bath and hand care for a daily ritual.',
  '選購身體乳',
  'Shop body lotion',
  '/products',
  '/images/stock/hero.jpg',
  UNIX_TIMESTAMP()
)
ON DUPLICATE KEY UPDATE `id` = `id`;

SELECT 'site_home_config 检查完成' AS result;
