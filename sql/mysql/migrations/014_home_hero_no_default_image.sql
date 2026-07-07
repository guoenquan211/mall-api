-- 清除首页 Hero 默认占位图（保留后台自行上传的图片）
SET NAMES utf8mb4;

UPDATE `site_home_config`
SET `hero_image` = NULL,
    `updated_at` = UNIX_TIMESTAMP()
WHERE `id` = 1
  AND TRIM(COALESCE(`hero_image`, '')) IN (
    '/images/stock/hero.jpg',
    'images/stock/hero.jpg',
    '/images/stock/tube.jpg',
    'images/stock/tube.jpg'
  );
