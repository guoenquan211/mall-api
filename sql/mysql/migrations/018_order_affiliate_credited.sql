-- 订单分销入账标记：付款通过后写入，避免重复累计消费/佣金
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

CALL mall_add_column('orders', 'affiliate_credited_at', "int(11) DEFAULT NULL COMMENT '分销入账时间(付款通过时)' AFTER `b3_user_id`");

DROP PROCEDURE IF EXISTS `mall_add_column`;
