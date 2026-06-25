-- CocoBrite mall-api 完整库结构（MySQL / MariaDB）
-- 用途：新建生产库时执行一次即可，已包含全部分销、GCash、双语字段。
-- 演示数据请另导 sql/mysql/seed_demo.sql

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE IF NOT EXISTS `products` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL COMMENT '商品名稱（繁體）',
  `name_en` varchar(255) DEFAULT NULL COMMENT '英文品名',
  `category` varchar(100) DEFAULT NULL COMMENT '分类',
  `description` text COMMENT '商品描述（繁體）',
  `description_en` text COMMENT '英文描述',
  `price` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '展示价格(最低价)',
  `image` varchar(255) DEFAULT NULL COMMENT '主图URL',
  `stock` int(11) NOT NULL DEFAULT '0' COMMENT '总库存',
  `status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '状态:1上架,0下架',
  `show_on_home` tinyint(1) NOT NULL DEFAULT '0' COMMENT '1=首页本季主推展示',
  `created_at` int(11) DEFAULT NULL,
  `updated_at` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='身体护理商品表(SPU)';

CREATE TABLE IF NOT EXISTS `product_categories` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL COMMENT '分類名稱（繁體）',
  `name_en` varchar(100) DEFAULT NULL COMMENT '英文名稱',
  `sort_order` int(11) NOT NULL DEFAULT '0' COMMENT '排序，越小越靠前',
  `status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '1启用 0停用',
  `created_at` int(11) DEFAULT NULL,
  `updated_at` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_pc_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='商品分类字典';

CREATE TABLE IF NOT EXISTS `product_variants` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `product_id` int(11) NOT NULL COMMENT '关联商品ID',
  `name` varchar(100) NOT NULL COMMENT '规格名称(如:400ml家庭装)',
  `price` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '规格价格',
  `stock` int(11) NOT NULL DEFAULT '0' COMMENT '规格库存',
  `image` varchar(255) DEFAULT NULL COMMENT '规格图片',
  `created_at` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `product_id` (`product_id`),
  CONSTRAINT `fk_product_variants_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='商品规格表(SKU)';

CREATE TABLE IF NOT EXISTS `news` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) NOT NULL COMMENT '標題（繁體）',
  `title_en` varchar(255) DEFAULT NULL COMMENT '英文標題',
  `category` varchar(100) DEFAULT NULL COMMENT '分类',
  `summary` varchar(500) DEFAULT NULL COMMENT '摘要（繁體）',
  `summary_en` varchar(500) DEFAULT NULL COMMENT '英文摘要',
  `content` longtext COMMENT '内容（繁體）',
  `content_en` longtext COMMENT '英文内容',
  `type` varchar(50) NOT NULL DEFAULT 'news' COMMENT '类型:news新闻,knowledge科普',
  `icon` varchar(512) DEFAULT NULL COMMENT '图标class或图片URL(科普类)',
  `cover_image` varchar(255) DEFAULT NULL COMMENT '封面图',
  `date` varchar(50) DEFAULT NULL COMMENT '显示日期',
  `source` varchar(100) DEFAULT NULL COMMENT '来源',
  `created_at` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='资讯科普表';

CREATE TABLE IF NOT EXISTS `product_images` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `product_id` int(11) NOT NULL COMMENT '商品ID',
  `image` varchar(255) NOT NULL COMMENT '图片URL',
  `sort` int(11) DEFAULT '0' COMMENT '排序',
  `created_at` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `product_id` (`product_id`),
  CONSTRAINT `fk_pimg_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='商品图片表';

CREATE TABLE IF NOT EXISTS `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(50) NOT NULL COMMENT '用户名',
  `password` varchar(255) NOT NULL COMMENT '密码',
  `nickname` varchar(50) DEFAULT NULL COMMENT '昵称',
  `avatar` varchar(255) DEFAULT NULL COMMENT '头像',
  `phone` varchar(20) DEFAULT NULL COMMENT '手机号',
  `email` varchar(100) DEFAULT NULL COMMENT '邮箱',
  `points` int(11) DEFAULT '0' COMMENT '积分',
  `invite_code` varchar(16) DEFAULT NULL COMMENT '邀请码',
  `parent_id` int(11) DEFAULT NULL COMMENT '邀请人用户ID',
  `affiliate_level` tinyint(1) NOT NULL DEFAULT '0' COMMENT '0普通 1一级 2二级 3三级',
  `total_paid_goods` decimal(14,2) NOT NULL DEFAULT '0.00' COMMENT '累计确认收货商品实付',
  `gcash_number` varchar(32) DEFAULT NULL COMMENT 'GCash 收款号',
  `gcash_name` varchar(100) DEFAULT NULL COMMENT 'GCash 收款人姓名',
  `status` tinyint(1) DEFAULT '1' COMMENT '状态:1正常,0禁用',
  `locale` varchar(16) NOT NULL DEFAULT 'zh-TW' COMMENT '介面語系 zh-TW|en',
  `created_at` int(11) DEFAULT NULL,
  `updated_at` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`),
  UNIQUE KEY `uk_users_invite_code` (`invite_code`),
  KEY `idx_users_parent` (`parent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

CREATE TABLE IF NOT EXISTS `user_addresses` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL COMMENT '用户ID',
  `name` varchar(50) NOT NULL COMMENT '收货人姓名',
  `phone` varchar(20) NOT NULL COMMENT '联系电话',
  `province` varchar(50) NOT NULL COMMENT '省',
  `city` varchar(50) NOT NULL COMMENT '市',
  `district` varchar(50) NOT NULL COMMENT '区/县',
  `detail` varchar(200) NOT NULL COMMENT '详细地址',
  `is_default` tinyint(1) DEFAULT '0' COMMENT '是否默认',
  `created_at` int(11) DEFAULT NULL,
  `updated_at` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `fk_address_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户收货地址表';

CREATE TABLE IF NOT EXISTS `user_favorites` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL COMMENT '用户ID',
  `product_id` int(11) NOT NULL COMMENT '商品ID',
  `created_at` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_product` (`user_id`, `product_id`),
  CONSTRAINT `fk_fav_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_fav_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户收藏表';

CREATE TABLE IF NOT EXISTS `orders` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `order_no` varchar(50) NOT NULL COMMENT '订单编号',
  `user_id` int(11) NOT NULL COMMENT '用户ID',
  `total_amount` decimal(10,2) NOT NULL COMMENT '订单总金额',
  `goods_amount` decimal(12,2) NOT NULL DEFAULT '0.00' COMMENT '商品实付合计(佣金基数)',
  `status` tinyint(1) DEFAULT '0' COMMENT '状态:0待付款,1待发货,2已发货,3已完成,4已取消',
  `payment_method` varchar(32) NOT NULL DEFAULT 'gcash' COMMENT '支付方式',
  `payment_status` varchar(32) NOT NULL DEFAULT 'pending' COMMENT 'pending|user_confirmed|approved|rejected',
  `payment_account_slot` tinyint(3) unsigned DEFAULT NULL COMMENT '收款账号槽位 1|2',
  `user_paid_at` int(11) DEFAULT NULL COMMENT '用户标记已付款时间',
  `payment_remark` text COMMENT '付款备注',
  `payment_proof_image` varchar(512) DEFAULT NULL COMMENT '付款凭证图',
  `payment_reject_reason` varchar(500) DEFAULT NULL COMMENT '驳回原因',
  `paid_at` int(11) DEFAULT NULL COMMENT '商家确认收款时间',
  `confirmed_at` int(11) DEFAULT NULL COMMENT '确认收货时间',
  `b1_user_id` int(11) DEFAULT NULL COMMENT '一级受益人快照',
  `b2_user_id` int(11) DEFAULT NULL COMMENT '二级受益人快照',
  `b3_user_id` int(11) DEFAULT NULL COMMENT '三级受益人快照',
  `express_company` varchar(50) DEFAULT NULL COMMENT '快递公司',
  `express_no` varchar(100) DEFAULT NULL COMMENT '快递单号',
  `address_snapshot` text COMMENT '收货地址快照',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `created_at` int(11) DEFAULT NULL,
  `updated_at` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `order_no` (`order_no`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `fk_order_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='订单表';

CREATE TABLE IF NOT EXISTS `order_items` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `order_id` int(11) NOT NULL COMMENT '订单ID',
  `product_id` int(11) NOT NULL COMMENT '商品ID',
  `variant_id` int(11) DEFAULT NULL COMMENT '规格ID',
  `product_name` varchar(255) NOT NULL COMMENT '商品名称快照',
  `product_image` varchar(255) DEFAULT NULL COMMENT '商品图片快照',
  `variant_name` varchar(100) DEFAULT NULL COMMENT '规格名称快照',
  `price` decimal(10,2) NOT NULL COMMENT '成交单价',
  `quantity` int(11) NOT NULL DEFAULT '1' COMMENT '购买数量',
  PRIMARY KEY (`id`),
  KEY `order_id` (`order_id`),
  CONSTRAINT `fk_item_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='订单商品详情表';

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

CREATE TABLE IF NOT EXISTS `user_affiliate_stats` (
  `user_id` int(11) NOT NULL,
  `downline_pv_total` decimal(14,2) NOT NULL DEFAULT '0.00',
  `updated_at` int(11) DEFAULT NULL,
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户分销统计';

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

CREATE TABLE IF NOT EXISTS `gcash_platform_accounts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `slot` tinyint(3) unsigned NOT NULL DEFAULT '1' COMMENT '槽位 1|2',
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

CREATE TABLE IF NOT EXISTS `admin_users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(50) NOT NULL COMMENT '用户名',
  `password` varchar(255) NOT NULL COMMENT '密码',
  `nickname` varchar(50) DEFAULT NULL COMMENT '昵称',
  `role` varchar(50) DEFAULT 'admin' COMMENT '角色:super_admin,editor,service',
  `avatar` varchar(255) DEFAULT NULL COMMENT '头像',
  `status` tinyint(1) DEFAULT '1' COMMENT '状态:1正常,0禁用',
  `last_login_at` int(11) DEFAULT NULL COMMENT '最后登录时间',
  `created_at` int(11) DEFAULT NULL,
  `updated_at` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='管理员表';

CREATE TABLE IF NOT EXISTS `admin_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `admin_id` int(11) NOT NULL COMMENT '管理员ID',
  `action` varchar(50) NOT NULL COMMENT '操作类型',
  `target` varchar(100) DEFAULT NULL COMMENT '操作对象',
  `detail` varchar(255) DEFAULT NULL COMMENT '操作详情',
  `ip` varchar(50) DEFAULT NULL COMMENT '操作IP',
  `created_at` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `admin_id` (`admin_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='后台操作日志表';

CREATE TABLE IF NOT EXISTS `contact_messages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `visitor_name` varchar(100) NOT NULL COMMENT '稱呼',
  `contact` varchar(255) DEFAULT NULL COMMENT '郵箱或電話',
  `content` text NOT NULL COMMENT '留言內容',
  `locale` varchar(16) NOT NULL DEFAULT 'zh-TW' COMMENT '介面語系',
  `ip` varchar(50) DEFAULT NULL COMMENT '來源IP',
  `status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '0未讀 1已讀(預留)',
  `created_at` int(11) DEFAULT NULL,
  `updated_at` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_cm_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='前台聯絡留言';

CREATE TABLE IF NOT EXISTS `user_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL COMMENT '用户ID',
  `action` varchar(50) NOT NULL COMMENT '操作',
  `detail` varchar(255) DEFAULT NULL COMMENT '详情',
  `ip` varchar(50) DEFAULT NULL COMMENT 'IP地址',
  `created_at` int(11) DEFAULT NULL,
  `updated_at` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户操作日志表';

SET FOREIGN_KEY_CHECKS = 1;

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

INSERT INTO `gcash_platform_accounts` (`slot`, `label`, `is_active`, `sort_order`, `created_at`, `updated_at`) VALUES
(1, 'GCash 账号 1', 1, 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
(2, 'GCash 账号 2', 1, 2, UNIX_TIMESTAMP(), UNIX_TIMESTAMP())
ON DUPLICATE KEY UPDATE `slot` = `slot`;
