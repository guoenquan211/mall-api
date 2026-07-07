-- 首页 Hero「查看详情」按钮配置
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

CALL mall_add_column('site_home_config', 'hero_detail_show', "tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否显示Hero查看详情按钮' AFTER `hero_image`");
CALL mall_add_column('site_home_config', 'hero_detail_text_zh', "varchar(64) DEFAULT NULL COMMENT '查看详情按钮(繁)' AFTER `hero_detail_show`");
CALL mall_add_column('site_home_config', 'hero_detail_text_en', "varchar(64) DEFAULT NULL COMMENT '查看详情按钮(英)' AFTER `hero_detail_text_zh`");
CALL mall_add_column('site_home_config', 'hero_detail_link_type', "varchar(20) NOT NULL DEFAULT '' COMMENT '链接类型:product|news|knowledge|custom' AFTER `hero_detail_text_en`");
CALL mall_add_column('site_home_config', 'hero_detail_link_value', "varchar(255) NOT NULL DEFAULT '' COMMENT '目标ID或自定义路径' AFTER `hero_detail_link_type`");

DROP PROCEDURE IF EXISTS `mall_add_column`;

UPDATE `site_home_config` SET
  `hero_detail_text_zh` = COALESCE(NULLIF(TRIM(`hero_detail_text_zh`), ''), '查看詳情'),
  `hero_detail_text_en` = COALESCE(NULLIF(TRIM(`hero_detail_text_en`), ''), 'View details')
WHERE `id` = 1;
