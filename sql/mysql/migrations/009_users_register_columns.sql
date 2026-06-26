-- 补全 users 表注册/分销字段（可重复执行，已存在的列/索引会自动跳过）

SET NAMES utf8mb4;

DROP PROCEDURE IF EXISTS `mall_add_users_column`;
DELIMITER $$
CREATE PROCEDURE `mall_add_users_column`(
    IN p_col VARCHAR(64),
    IN p_def TEXT
)
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'users'
          AND COLUMN_NAME = p_col
    ) THEN
        SET @sql = CONCAT('ALTER TABLE `users` ADD COLUMN `', p_col, '` ', p_def);
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;
END$$
DELIMITER ;

CALL mall_add_users_column('invite_code', "varchar(16) DEFAULT NULL COMMENT '邀请码' AFTER `points`");
CALL mall_add_users_column('parent_id', "int(11) DEFAULT NULL COMMENT '邀请人用户ID' AFTER `invite_code`");
CALL mall_add_users_column('affiliate_level', "tinyint(1) NOT NULL DEFAULT 0 COMMENT '分销等级' AFTER `parent_id`");
CALL mall_add_users_column('total_paid_goods', "decimal(14,2) NOT NULL DEFAULT 0.00 COMMENT '累计确认收货商品实付' AFTER `affiliate_level`");
CALL mall_add_users_column('gcash_number', "varchar(32) DEFAULT NULL COMMENT 'GCash 收款号' AFTER `total_paid_goods`");
CALL mall_add_users_column('gcash_name', "varchar(100) DEFAULT NULL COMMENT 'GCash 收款人姓名' AFTER `gcash_number`");
CALL mall_add_users_column('locale', "varchar(16) NOT NULL DEFAULT 'zh-TW' COMMENT '介面語系' AFTER `status`");

DROP PROCEDURE IF EXISTS `mall_add_users_column`;

-- 索引（不存在才加）
SET @idx_exists = (
    SELECT COUNT(*) FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND INDEX_NAME = 'uk_users_invite_code'
);
SET @sql = IF(@idx_exists = 0, 'ALTER TABLE `users` ADD UNIQUE KEY `uk_users_invite_code` (`invite_code`)', 'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists = (
    SELECT COUNT(*) FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND INDEX_NAME = 'idx_users_parent'
);
SET @sql = IF(@idx_exists = 0, 'ALTER TABLE `users` ADD KEY `idx_users_parent` (`parent_id`)', 'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SELECT 'users 表字段检查完成' AS result;
