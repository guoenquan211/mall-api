CREATE TABLE IF NOT EXISTS `products` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL COMMENT '商品名称',
  `category` varchar(100) DEFAULT NULL COMMENT '分类',
  `description` text COMMENT '商品描述',
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
  `name` varchar(100) NOT NULL COMMENT '分类名称',
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
  `title` varchar(255) NOT NULL COMMENT '标题',
  `category` varchar(100) DEFAULT NULL COMMENT '分类',
  `summary` varchar(500) DEFAULT NULL COMMENT '摘要',
  `content` longtext COMMENT '内容',
  `type` varchar(50) NOT NULL DEFAULT 'news' COMMENT '类型:news新闻,knowledge科普',
  `icon` varchar(50) DEFAULT NULL COMMENT '图标(科普类)',
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
  `parent_id` int(11) DEFAULT NULL COMMENT '邀请人',
  `affiliate_level` tinyint(1) NOT NULL DEFAULT '0' COMMENT '0普通1一级2二级3三级',
  `total_paid_goods` decimal(14,2) NOT NULL DEFAULT '0.00' COMMENT '累计确认收货商品实付',
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
  `goods_amount` decimal(12,2) NOT NULL DEFAULT '0.00' COMMENT '商品实付(佣金基数)',
  `status` tinyint(1) DEFAULT '0' COMMENT '状态:0待付款,1待发货,2已发货,3已完成,4已取消',
  `paid_at` int(11) DEFAULT NULL COMMENT '支付时间',
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
  `currency_suffix` varchar(8) NOT NULL DEFAULT 'P',
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='分销全局配置';

CREATE TABLE IF NOT EXISTS `user_affiliate_stats` (
  `user_id` int(11) NOT NULL,
  `downline_pv_total` decimal(14,2) NOT NULL DEFAULT '0.00',
  `updated_at` int(11) DEFAULT NULL,
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户分销统计';

CREATE TABLE IF NOT EXISTS `commission_records` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `order_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `tier` tinyint(3) unsigned NOT NULL,
  `goods_base` decimal(12,2) NOT NULL DEFAULT '0.00',
  `rate` decimal(8,4) NOT NULL DEFAULT '0.0000',
  `amount` decimal(12,2) NOT NULL DEFAULT '0.00',
  `status` varchar(16) NOT NULL DEFAULT 'pending',
  `unlock_at` int(11) NOT NULL DEFAULT '0',
  `settled_period` varchar(16) DEFAULT NULL,
  `created_at` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_cr_user` (`user_id`),
  KEY `idx_cr_order` (`order_id`),
  KEY `idx_cr_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='佣金流水';

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

-- Insert Demo Data
INSERT INTO `admin_users` (`username`, `password`, `nickname`, `role`, `created_at`) VALUES
('admin', '$2y$10$abcdefg...', '超级管理员', 'super_admin', UNIX_TIMESTAMP());

INSERT INTO `affiliate_program_config` (`id`, `currency_suffix`, `level1_name`, `level2_name`, `level3_name`,
  `level1_spend_threshold`, `level1_any_order`, `level2_direct_l1_min`, `level2_team_pv`,
  `level3_direct_l2_min`, `level3_team_pv`, `commission_rate_1`, `commission_rate_2`, `commission_rate_3`,
  `settlement_day`, `after_sale_days`, `reward_rules_text`, `public_slogans_text`, `updated_at`)
VALUES (1, 'P', '美妆分享官', '美妆达人', '美妆合伙人',
  1000.00, 1, 5, 5000.00, 3, 20000.00, 0.2000, 0.1000, 0.0400, 10, 7,
  '自用省钱，分享赚钱\n• 你推荐朋友买 → 你拿一级佣金（20%）\n• 朋友再推荐别人买 → 你拿二级佣金（10%）\n• 朋友的下级再推荐买 → 你拿三级佣金（4%）',
  '模式总则（合规底线）\n• 合法三级分销，不设四级及以上层级\n• 佣金仅基于真实美妆商品成交订单，不按人头计酬\n• 无入门费、无强制囤货、无高价入门礼包，推广资格免费开通\n\n有效订单：支付完成 → 确认收货 → 7天无售后 → 佣金生效\n结算：每月10号结算上一自然月可提现佣金',
  UNIX_TIMESTAMP());

INSERT INTO `product_categories` (`name`, `sort_order`, `status`, `created_at`, `updated_at`) VALUES
('身体护理', 10, 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
('香氛身体乳', 20, 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
('手足护理', 30, 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
('沐浴', 40, 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
('礼盒', 50, 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP());

INSERT INTO `products` (`name`, `category`, `description`, `price`, `image`, `stock`, `status`, `show_on_home`, `created_at`) VALUES
('CocoBrite 光感美白身体乳', '身体护理', '烟酰胺与透明质酸协同，轻盈乳液质地，易吸收不假滑。实际效果因人而异。', 168.00, '/images/stock/lotion.jpg', 200, 1, 1, UNIX_TIMESTAMP()),
('CocoBrite 栀子花香氛身体乳', '香氛身体乳', '淡雅花香，保湿润泽，适合日常浴后护理。', 128.00, '/images/stock/tube.jpg', 150, 1, 1, UNIX_TIMESTAMP()),
('CocoBrite 果酸柔滑身体乳', '身体护理', '温和果酸，帮助改善粗糙角质（敏感肌请先局部测试）。', 158.00, '/images/stock/spa.jpg', 90, 1, 1, UNIX_TIMESTAMP()),
('CocoBrite 维C亮采护手霜', '手足护理', '小巧便携，手部保湿提亮。', 48.00, '/images/stock/tube.jpg', 300, 1, 0, UNIX_TIMESTAMP()),
('CocoBrite 身体精华油', '身体护理', '以油养肤，浴后按摩使用，滋润不黏腻。', 188.00, '/images/stock/lotion.jpg', 60, 1, 0, UNIX_TIMESTAMP()),
('CocoBrite 沐浴慕斯', '沐浴', '绵密泡沫，温和清洁，洗后不紧绷。', 88.00, '/images/stock/spa.jpg', 120, 1, 0, UNIX_TIMESTAMP()),
('CocoBrite 磨砂膏（椰奶香）', '身体护理', '细腻颗粒，关节暗沉部位轻柔打圈使用。', 118.00, '/images/stock/spa.jpg', 75, 1, 0, UNIX_TIMESTAMP()),
('CocoBrite 旅行装四件套', '礼盒', '身体乳+沐浴+手霜+发膜小样，出差旅行常备。', 99.00, '/images/stock/tube.jpg', 200, 1, 0, UNIX_TIMESTAMP());

INSERT INTO `product_variants` (`product_id`, `name`, `price`, `stock`, `created_at`) VALUES
(1, '400ml 家庭装', 168.00, 120, UNIX_TIMESTAMP()),
(1, '200ml 便携装', 98.00, 80, UNIX_TIMESTAMP()),
(2, '300ml', 128.00, 100, UNIX_TIMESTAMP()),
(2, '300ml 双支礼盒', 238.00, 50, UNIX_TIMESTAMP());

INSERT INTO `news` (`title`, `summary`, `content`, `type`, `source`, `created_at`) VALUES
('CocoBrite 光感美白身体乳焕新上市', '主打烟酰胺协同透明质酸，浴后三步护理更易坚持。', '<p>演示数据：新品与成分故事请以实物标签及备案信息为准。</p>', 'news', '品牌官方', UNIX_TIMESTAMP()),
('浴后身体乳正确涂抹顺序', '先擦干水分再涂抹，关节处可略多涂，配合轻柔按摩促进吸收。', '<p>演示数据：个体差异存在，如有不适请停用并咨询专业人士。</p>', 'knowledge', '护理实验室', UNIX_TIMESTAMP());

INSERT INTO `news` (`title`, `summary`, `content`, `type`, `icon`, `source`, `created_at`) VALUES
('干燥季如何叠涂身体乳与精油', '先乳后油更锁水，注意用量避免黏腻。', '<h3>步骤</h3><p>沐浴后趁角质含水，先涂身体乳再叠加少量身体油。</p>', 'knowledge', 'ri-drop-line', 'CocoBrite 实验室', UNIX_TIMESTAMP()),
('美白身体乳可以涂脸吗', '通常不建议，面部角质与耐受与身体肌肤不同。', '<p>身体乳仅供身体使用；面部请选面部专用产品。</p>', 'knowledge', 'ri-information-line', NULL, UNIX_TIMESTAMP()),
('果酸身体乳入门：频率与防晒', '温和起步，循序渐进，白天注意防晒。', '<p>敏感肌先局部测试；出现刺痛红肿请停用。</p>', 'knowledge', 'ri-sun-line', NULL, UNIX_TIMESTAMP()),
('香氛身体乳留香小技巧', '可轻点同款香氛于脉搏点，层次更自然。', '<p>演示内容：香氛浓度因个人喜好调整。</p>', 'knowledge', 'ri-flask-line', NULL, UNIX_TIMESTAMP()),
('身体美白的常见误区', '角质层健康与保湿是光泽感前提。', '<p>化妆品功效宣称以标签为准；效果因人而异。</p>', 'knowledge', 'ri-book-open-line', NULL, UNIX_TIMESTAMP());

INSERT INTO `users` (`username`, `password`, `nickname`, `created_at`) VALUES
('user001', '$2y$10$hijklmn...', '身体护理爱好者', UNIX_TIMESTAMP());

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
