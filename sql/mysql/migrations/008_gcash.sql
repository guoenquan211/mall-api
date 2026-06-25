-- GCash 收款与佣金提现（MySQL 老库升级）
-- 新库请直接用 sql/mysql/schema_full.sql，无需执行本文件。

SET NAMES utf8mb4;

ALTER TABLE `users`
  ADD COLUMN `gcash_number` varchar(32) DEFAULT NULL COMMENT 'GCash 收款号' AFTER `total_paid_goods`,
  ADD COLUMN `gcash_name` varchar(100) DEFAULT NULL COMMENT 'GCash 收款人姓名' AFTER `gcash_number`;

ALTER TABLE `orders`
  ADD COLUMN `payment_method` varchar(32) NOT NULL DEFAULT 'gcash' COMMENT '支付方式' AFTER `status`,
  ADD COLUMN `payment_status` varchar(32) NOT NULL DEFAULT 'pending' COMMENT 'pending|user_confirmed|approved|rejected' AFTER `payment_method`,
  ADD COLUMN `payment_account_slot` tinyint(3) unsigned DEFAULT NULL COMMENT '收款账号槽位' AFTER `payment_status`,
  ADD COLUMN `user_paid_at` int(11) DEFAULT NULL COMMENT '用户标记已付款时间' AFTER `payment_account_slot`,
  ADD COLUMN `payment_remark` text COMMENT '付款备注' AFTER `user_paid_at`,
  ADD COLUMN `payment_proof_image` varchar(512) DEFAULT NULL COMMENT '付款凭证图' AFTER `payment_remark`,
  ADD COLUMN `payment_reject_reason` varchar(500) DEFAULT NULL COMMENT '驳回原因' AFTER `payment_proof_image`;

CREATE TABLE IF NOT EXISTS `gcash_platform_accounts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `slot` tinyint(3) unsigned NOT NULL DEFAULT '1',
  `label` varchar(100) NOT NULL DEFAULT '',
  `account_name` varchar(100) DEFAULT NULL,
  `mobile` varchar(32) DEFAULT NULL,
  `qr_image` varchar(512) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `sort_order` int(11) NOT NULL DEFAULT '0',
  `created_at` int(11) DEFAULT NULL,
  `updated_at` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_gcash_slot` (`slot`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='平台 GCash 收款账号';

CREATE TABLE IF NOT EXISTS `withdrawal_requests` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `amount` decimal(12,2) NOT NULL,
  `gcash_number` varchar(32) NOT NULL,
  `gcash_name` varchar(100) NOT NULL,
  `status` varchar(16) NOT NULL DEFAULT 'pending',
  `admin_note` varchar(500) DEFAULT NULL,
  `payout_ref` varchar(100) DEFAULT NULL,
  `processed_at` int(11) DEFAULT NULL,
  `created_at` int(11) DEFAULT NULL,
  `updated_at` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_withdrawal_user` (`user_id`),
  KEY `idx_withdrawal_status` (`status`),
  CONSTRAINT `fk_withdrawal_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='佣金提现申请';

INSERT INTO `gcash_platform_accounts` (`slot`, `label`, `is_active`, `sort_order`, `created_at`, `updated_at`) VALUES
(1, 'GCash 账号 1', 1, 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
(2, 'GCash 账号 2', 1, 2, UNIX_TIMESTAMP(), UNIX_TIMESTAMP())
ON DUPLICATE KEY UPDATE `slot` = `slot`;
