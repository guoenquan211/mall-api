-- 订单实时物流追踪链接（Lalamove / Grab / 第三方配送）
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

CALL mall_add_column(
    'orders',
    'express_tracking_url',
    "varchar(1000) DEFAULT NULL COMMENT '实时物流追踪链接' AFTER `express_no`"
);

DROP PROCEDURE IF EXISTS `mall_add_column`;
