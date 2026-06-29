-- 分销/邀请体系（可重复执行，已存在的列/表/索引会自动跳过）
-- 推广与佣金页依赖：affiliate_program_config、user_affiliate_stats、commission_records

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

-- users 分销字段
CALL mall_add_column('users', 'invite_code', "varchar(16) DEFAULT NULL COMMENT '邀请码' AFTER `points`");
CALL mall_add_column('users', 'parent_id', "int(11) DEFAULT NULL COMMENT '邀请人用户ID' AFTER `invite_code`");
CALL mall_add_column('users', 'affiliate_level', "tinyint(1) NOT NULL DEFAULT 0 COMMENT '分销等级' AFTER `parent_id`");
CALL mall_add_column('users', 'total_paid_goods', "decimal(14,2) NOT NULL DEFAULT 0.00 COMMENT '累计确认收货商品实付' AFTER `affiliate_level`");

-- orders 分销字段
CALL mall_add_column('orders', 'remark', "varchar(500) DEFAULT NULL COMMENT '备注' AFTER `address_snapshot`");
CALL mall_add_column('orders', 'goods_amount', "decimal(12,2) NOT NULL DEFAULT 0.00 COMMENT '商品实付合计(佣金基数)' AFTER `total_amount`");
CALL mall_add_column('orders', 'paid_at', "int(11) DEFAULT NULL COMMENT '支付时间' AFTER `status`");
CALL mall_add_column('orders', 'confirmed_at', "int(11) DEFAULT NULL COMMENT '确认收货时间' AFTER `paid_at`");
CALL mall_add_column('orders', 'b1_user_id', "int(11) DEFAULT NULL COMMENT '一级受益人快照' AFTER `confirmed_at`");
CALL mall_add_column('orders', 'b2_user_id', "int(11) DEFAULT NULL COMMENT '二级受益人快照' AFTER `b1_user_id`");
CALL mall_add_column('orders', 'b3_user_id', "int(11) DEFAULT NULL COMMENT '三级受益人快照' AFTER `b2_user_id`");

DROP PROCEDURE IF EXISTS `mall_add_column`;

-- users 索引
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

-- 分销配置表
CREATE TABLE IF NOT EXISTS `affiliate_program_config` (
  `id` tinyint(3) unsigned NOT NULL DEFAULT '1',
  `currency_suffix` varchar(8) NOT NULL DEFAULT 'P' COMMENT '金额后缀展示',
  `level1_name` varchar(64) NOT NULL DEFAULT '美妆分享官',
  `level2_name` varchar(64) NOT NULL DEFAULT '美妆达人',
  `level3_name` varchar(64) NOT NULL DEFAULT '美妆合伙人',
  `level1_spend_threshold` decimal(12,2) NOT NULL DEFAULT '1000.00',
  `level1_any_order` tinyint(1) NOT NULL DEFAULT '1',
  `level2_direct_l1_min` int(11) NOT NULL DEFAULT '5',
  `level2_team_pv` decimal(14,2) NOT NULL DEFAULT '5000.00',
  `level3_direct_l2_min` int(11) NOT NULL DEFAULT '3',
  `level3_team_pv` decimal(14,2) NOT NULL DEFAULT '20000.00',
  `commission_rate_1` decimal(8,4) NOT NULL DEFAULT '0.2000',
  `commission_rate_2` decimal(8,4) NOT NULL DEFAULT '0.1000',
  `commission_rate_3` decimal(8,4) NOT NULL DEFAULT '0.0400',
  `settlement_day` tinyint(3) unsigned NOT NULL DEFAULT '10',
  `after_sale_days` tinyint(3) unsigned NOT NULL DEFAULT '7',
  `reward_rules_text` text,
  `public_slogans_text` text,
  `updated_at` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='分销全局配置(单行)';

INSERT INTO `affiliate_program_config` (`id`, `currency_suffix`, `level1_name`, `level2_name`, `level3_name`,
  `level1_spend_threshold`, `level1_any_order`, `level2_direct_l1_min`, `level2_team_pv`,
  `level3_direct_l2_min`, `level3_team_pv`, `commission_rate_1`, `commission_rate_2`, `commission_rate_3`,
  `settlement_day`, `after_sale_days`, `reward_rules_text`, `public_slogans_text`, `updated_at`)
VALUES (1, 'P', '美妆分享官', '美妆达人', '美妆合伙人',
  1000.00, 1, 5, 5000.00, 3, 20000.00, 0.2000, 0.1000, 0.0400, 10, 7,
  '自用省钱，分享赚钱\n• 你推荐朋友买 → 你拿一级佣金\n• 朋友再推荐别人买 → 你拿二级佣金\n• 朋友的下级再推荐买 → 你拿三级佣金',
  '美妆自用省钱，分享赚钱\n三级分销，真实卖货拿佣金\n无加盟费、无囤货、无压力\n卖产品都能赚，分享就能变现',
  UNIX_TIMESTAMP())
ON DUPLICATE KEY UPDATE `id` = `id`;

-- 用户分销统计
CREATE TABLE IF NOT EXISTS `user_affiliate_stats` (
  `user_id` int(11) NOT NULL,
  `downline_pv_total` decimal(14,2) NOT NULL DEFAULT '0.00',
  `updated_at` int(11) DEFAULT NULL,
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户分销统计缓存';

-- 佣金流水
CREATE TABLE IF NOT EXISTS `commission_records` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `order_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL COMMENT '受益人',
  `tier` tinyint(3) unsigned NOT NULL COMMENT '1直推2间推3团队',
  `goods_base` decimal(12,2) NOT NULL DEFAULT '0.00',
  `rate` decimal(8,4) NOT NULL DEFAULT '0.0000',
  `amount` decimal(12,2) NOT NULL DEFAULT '0.00',
  `status` varchar(16) NOT NULL DEFAULT 'pending' COMMENT 'pending|available|settled|void',
  `unlock_at` int(11) NOT NULL DEFAULT '0',
  `settled_period` varchar(16) DEFAULT NULL,
  `created_at` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_cr_user` (`user_id`),
  KEY `idx_cr_order` (`order_id`),
  KEY `idx_cr_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='佣金流水';

SELECT 'affiliate 分销表检查完成' AS result;
