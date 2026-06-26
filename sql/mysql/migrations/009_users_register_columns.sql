-- 补全 users 表注册/分销所需字段（老库升级，可重复执行时忽略 Duplicate column 报错）

SET NAMES utf8mb4;

ALTER TABLE `users` ADD COLUMN `invite_code` varchar(16) DEFAULT NULL COMMENT '邀请码' AFTER `points`;
ALTER TABLE `users` ADD COLUMN `parent_id` int(11) DEFAULT NULL COMMENT '邀请人用户ID' AFTER `invite_code`;
ALTER TABLE `users` ADD COLUMN `affiliate_level` tinyint(1) NOT NULL DEFAULT 0 COMMENT '分销等级' AFTER `parent_id`;
ALTER TABLE `users` ADD COLUMN `total_paid_goods` decimal(14,2) NOT NULL DEFAULT 0.00 COMMENT '累计确认收货商品实付' AFTER `affiliate_level`;
ALTER TABLE `users` ADD COLUMN `gcash_number` varchar(32) DEFAULT NULL COMMENT 'GCash 收款号' AFTER `total_paid_goods`;
ALTER TABLE `users` ADD COLUMN `gcash_name` varchar(100) DEFAULT NULL COMMENT 'GCash 收款人姓名' AFTER `gcash_number`;
ALTER TABLE `users` ADD COLUMN `locale` varchar(16) NOT NULL DEFAULT 'zh-TW' COMMENT '介面語系' AFTER `status`;

ALTER TABLE `users` ADD UNIQUE KEY `uk_users_invite_code` (`invite_code`);
ALTER TABLE `users` ADD KEY `idx_users_parent` (`parent_id`);
