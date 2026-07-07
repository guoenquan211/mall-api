-- 主按钮链接改为可视化选择（类型 + 目标ID）
SET NAMES utf8mb4;

DROP PROCEDURE IF EXISTS `mall_add_column`;
DELIMITER $$
CREATE PROCEDURE `mall_add_column`(
    IN p_table VARCHAR(64),
    IN p_col VARCHAR(64),
    IN p_def TEXT
)
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = p_table
          AND COLUMN_NAME = p_col
    ) THEN
        SET @sql = CONCAT('ALTER TABLE `', p_table, '` ADD COLUMN `', p_col, '` ', p_def);
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;
END$$
DELIMITER ;

CALL mall_add_column('site_home_config', 'hero_cta_link_type', "varchar(20) NOT NULL DEFAULT '' COMMENT '主按钮链接类型' AFTER `hero_cta_link`");
CALL mall_add_column('site_home_config', 'hero_cta_link_value', "varchar(255) NOT NULL DEFAULT '' COMMENT '主按钮链接目标' AFTER `hero_cta_link_type`");

DROP PROCEDURE IF EXISTS `mall_add_column`;

UPDATE `site_home_config` SET
  `hero_cta_link_type` = CASE
    WHEN TRIM(COALESCE(`hero_cta_link`, '')) = '#home-collection' THEN 'home_collection'
    WHEN TRIM(COALESCE(`hero_cta_link`, '')) = '/products' THEN 'products'
    WHEN TRIM(COALESCE(`hero_cta_link`, '')) REGEXP '^/product/[0-9]+$' THEN 'product'
    WHEN TRIM(COALESCE(`hero_cta_link`, '')) REGEXP '^/news\\?id=[0-9]+$' THEN 'news'
    WHEN TRIM(COALESCE(`hero_cta_link`, '')) REGEXP '^/knowledge\\?id=[0-9]+$' THEN 'knowledge'
    ELSE 'products'
  END,
  `hero_cta_link_value` = CASE
    WHEN TRIM(COALESCE(`hero_cta_link`, '')) REGEXP '^/product/([0-9]+)$' THEN SUBSTRING_INDEX(TRIM(`hero_cta_link`), '/', -1)
    WHEN TRIM(COALESCE(`hero_cta_link`, '')) REGEXP '^/news\\?id=([0-9]+)$' THEN SUBSTRING_INDEX(TRIM(`hero_cta_link`), '=', -1)
    WHEN TRIM(COALESCE(`hero_cta_link`, '')) REGEXP '^/knowledge\\?id=([0-9]+)$' THEN SUBSTRING_INDEX(TRIM(`hero_cta_link`), '=', -1)
    ELSE ''
  END
WHERE `id` = 1
  AND (TRIM(COALESCE(`hero_cta_link_type`, '')) = '');

UPDATE `site_home_config`
SET
  `hero_detail_link_type` = '',
  `hero_detail_link_value` = ''
WHERE `id` = 1
  AND TRIM(COALESCE(`hero_detail_link_type`, '')) = 'custom';
