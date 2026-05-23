-- 分销/邀请体系（MySQL）。请在备份后执行；可重复执行时需自行处理重复列错误。

SET NAMES utf8mb4;

ALTER TABLE `users`
  ADD COLUMN `invite_code` varchar(16) DEFAULT NULL COMMENT '邀请码' AFTER `points`,
  ADD COLUMN `parent_id` int(11) DEFAULT NULL COMMENT '邀请人用户ID' AFTER `invite_code`,
  ADD COLUMN `affiliate_level` tinyint(1) NOT NULL DEFAULT '0' COMMENT '0普通 1一级 2二级 3三级' AFTER `parent_id`,
  ADD COLUMN `total_paid_goods` decimal(14,2) NOT NULL DEFAULT '0.00' COMMENT '累计确认收货商品实付(计级用)' AFTER `affiliate_level`;

ALTER TABLE `users`
  ADD UNIQUE KEY `uk_users_invite_code` (`invite_code`),
  ADD KEY `idx_users_parent` (`parent_id`);

ALTER TABLE `orders`
  ADD COLUMN `remark` varchar(500) DEFAULT NULL COMMENT '备注' AFTER `address_snapshot`,
  ADD COLUMN `goods_amount` decimal(12,2) NOT NULL DEFAULT '0.00' COMMENT '商品实付合计(佣金基数)' AFTER `total_amount`,
  ADD COLUMN `paid_at` int(11) DEFAULT NULL COMMENT '支付时间' AFTER `status`,
  ADD COLUMN `confirmed_at` int(11) DEFAULT NULL COMMENT '确认收货时间' AFTER `paid_at`,
  ADD COLUMN `b1_user_id` int(11) DEFAULT NULL COMMENT '下单时一级受益人快照' AFTER `confirmed_at`,
  ADD COLUMN `b2_user_id` int(11) DEFAULT NULL COMMENT '二级受益人快照' AFTER `b1_user_id`,
  ADD COLUMN `b3_user_id` int(11) DEFAULT NULL COMMENT '三级受益人快照' AFTER `b2_user_id`;

CREATE TABLE IF NOT EXISTS `affiliate_program_config` (
  `id` tinyint(3) unsigned NOT NULL DEFAULT '1',
  `currency_suffix` varchar(8) NOT NULL DEFAULT 'P' COMMENT '金额后缀展示',
  `level1_name` varchar(64) NOT NULL DEFAULT '美妆分享官',
  `level2_name` varchar(64) NOT NULL DEFAULT '美妆达人',
  `level3_name` varchar(64) NOT NULL DEFAULT '美妆合伙人',
  `level1_spend_threshold` decimal(12,2) NOT NULL DEFAULT '1000.00' COMMENT '一级-消费升级阈值',
  `level1_any_order` tinyint(1) NOT NULL DEFAULT '1' COMMENT '一级-任意一笔美妆订单即达标',
  `level2_direct_l1_min` int(11) NOT NULL DEFAULT '5' COMMENT '二级-直推一级有效人数',
  `level2_team_pv` decimal(14,2) NOT NULL DEFAULT '5000.00' COMMENT '二级-团队业绩',
  `level3_direct_l2_min` int(11) NOT NULL DEFAULT '3' COMMENT '三级-直推二级有效人数',
  `level3_team_pv` decimal(14,2) NOT NULL DEFAULT '20000.00' COMMENT '三级-团队总业绩',
  `commission_rate_1` decimal(8,4) NOT NULL DEFAULT '0.2000',
  `commission_rate_2` decimal(8,4) NOT NULL DEFAULT '0.1000',
  `commission_rate_3` decimal(8,4) NOT NULL DEFAULT '0.0400',
  `settlement_day` tinyint(3) unsigned NOT NULL DEFAULT '10' COMMENT '每月结算日',
  `after_sale_days` tinyint(3) unsigned NOT NULL DEFAULT '7' COMMENT '确认收货后无纠纷锁定天数',
  `reward_rules_text` text COMMENT '奖励说明(后台可改)',
  `public_slogans_text` text COMMENT '对外宣传文案(后台可改)',
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

CREATE TABLE IF NOT EXISTS `user_affiliate_stats` (
  `user_id` int(11) NOT NULL,
  `downline_pv_total` decimal(14,2) NOT NULL DEFAULT '0.00' COMMENT '全团队业绩(含多级下级订单商品实付累计)',
  `updated_at` int(11) DEFAULT NULL,
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户分销统计缓存';

CREATE TABLE IF NOT EXISTS `commission_records` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `order_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL COMMENT '受益人',
  `tier` tinyint(3) unsigned NOT NULL COMMENT '1直推2间推3团队',
  `goods_base` decimal(12,2) NOT NULL DEFAULT '0.00',
  `rate` decimal(8,4) NOT NULL DEFAULT '0.0000',
  `amount` decimal(12,2) NOT NULL DEFAULT '0.00',
  `status` varchar(16) NOT NULL DEFAULT 'pending' COMMENT 'pending|available|settled|void',
  `unlock_at` int(11) NOT NULL DEFAULT '0' COMMENT '到达后可结算/可提现逻辑用',
  `settled_period` varchar(16) DEFAULT NULL COMMENT '结算批次如2026-05',
  `created_at` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_cr_user` (`user_id`),
  KEY `idx_cr_order` (`order_id`),
  KEY `idx_cr_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='佣金流水';
