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
  `status` tinyint(1) DEFAULT '1' COMMENT '状态:1正常,0禁用',
  `locale` varchar(16) NOT NULL DEFAULT 'en' COMMENT '介面語系 zh-TW|en',
  `created_at` int(11) DEFAULT NULL,
  `updated_at` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`)
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
  `status` tinyint(1) DEFAULT '0' COMMENT '状态:0待付款,1待发货,2已发货,3已完成,4已取消',
  `express_company` varchar(50) DEFAULT NULL COMMENT '快递公司',
  `express_no` varchar(100) DEFAULT NULL COMMENT '快递单号',
  `address_snapshot` text COMMENT '收货地址快照',
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

INSERT INTO `product_categories` (`name`, `name_en`, `sort_order`, `status`, `created_at`, `updated_at`) VALUES
('身體護理', 'Body care', 10, 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
('香氛身體乳', 'Scented body lotion', 20, 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
('手足護理', 'Hand & foot care', 30, 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
('沐浴', 'Bath', 40, 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
('禮盒', 'Gift sets', 50, 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP());

INSERT INTO `products` (`name`, `name_en`, `category`, `description`, `description_en`, `price`, `image`, `stock`, `status`, `show_on_home`, `created_at`) VALUES
('CocoBrite 光感美白身體乳', 'CocoBrite Radiance Body Lotion', '身體護理', '煙醯胺與透明質酸協同，輕盈乳液質地，易吸收不假滑。實際效果因人而異。', 'Niacinamide and hyaluronic acid in a lightweight lotion. Individual results may vary.', 168.00, '/images/stock/lotion.jpg', 200, 1, 1, UNIX_TIMESTAMP()),
('CocoBrite 梔子花香氛身體乳', 'CocoBrite Gardenia Body Lotion', '香氛身體乳', '淡雅花香，保濕潤澤，適合日常浴後護理。', 'Soft floral scent with daily moisturizing after bathing.', 128.00, '/images/stock/tube.jpg', 150, 1, 1, UNIX_TIMESTAMP()),
('CocoBrite 果酸柔滑身體乳', 'CocoBrite AHA Smoothing Lotion', '身體護理', '溫和果酸，幫助改善粗糙角質（敏感肌請先局部測試）。', 'Gentle AHAs for rough texture. Patch test if sensitive.', 158.00, '/images/stock/spa.jpg', 90, 1, 1, UNIX_TIMESTAMP()),
('CocoBrite 維C亮采護手霜', 'CocoBrite Vitamin C Hand Cream', '手足護理', '小巧便攜，手部保濕提亮。', 'Travel-friendly hand hydration and brightening.', 48.00, '/images/stock/tube.jpg', 300, 1, 0, UNIX_TIMESTAMP()),
('CocoBrite 身體精華油', 'CocoBrite Body Serum Oil', '身體護理', '以油養膚，浴後按摩使用，滋潤不黏膩。', 'Oil-rich care for post-bath massage without greasiness.', 188.00, '/images/stock/lotion.jpg', 60, 1, 0, UNIX_TIMESTAMP()),
('CocoBrite 沐浴慕斯', 'CocoBrite Bath Mousse', '沐浴', '綿密泡沫，溫和清潔，洗後不緊繃。', 'Rich foam, gentle cleanse, comfortable after rinse.', 88.00, '/images/stock/spa.jpg', 120, 1, 0, UNIX_TIMESTAMP()),
('CocoBrite 磨砂膏（椰奶香）', 'CocoBrite Body Scrub (Coconut)', '身體護理', '細膩顆粒，關節暗沉部位輕柔打圈使用。', 'Fine grains; gently buff dull areas.', 118.00, '/images/stock/spa.jpg', 75, 1, 0, UNIX_TIMESTAMP()),
('CocoBrite 旅行裝四件套', 'CocoBrite Travel Set (4 pcs)', '禮盒', '身體乳+沐浴+手霜+髮膜小樣，出差旅行常備。', 'Lotion, bath, hand cream & hair mask minis for travel.', 99.00, '/images/stock/tube.jpg', 200, 1, 0, UNIX_TIMESTAMP());

INSERT INTO `product_variants` (`product_id`, `name`, `price`, `stock`, `created_at`) VALUES
(1, '400ml 家庭装', 168.00, 120, UNIX_TIMESTAMP()),
(1, '200ml 便携装', 98.00, 80, UNIX_TIMESTAMP()),
(2, '300ml', 128.00, 100, UNIX_TIMESTAMP()),
(2, '300ml 双支礼盒', 238.00, 50, UNIX_TIMESTAMP());

INSERT INTO `news` (`title`, `title_en`, `summary`, `summary_en`, `content`, `content_en`, `type`, `source`, `created_at`) VALUES
('CocoBrite 光感美白身體乳煥新上市', 'CocoBrite Radiance Body Lotion Launch', '主打煙醯胺協同透明質酸，浴後三步護理更易堅持。', 'Niacinamide + HA and a simple 3-step after-bath routine.', '<p>示範內容：新品與成分故事請以實物標籤及備案資訊為準。</p>', '<p>Demo copy; see packaging and local regulations for claims.</p>', 'news', '品牌官方', UNIX_TIMESTAMP()),
('浴後身體乳正確塗抹順序', 'How to apply body lotion after bathing', '先擦乾水分再塗抹，關節處可略多塗，配合輕柔按摩促進吸收。', 'Pat dry, apply more on joints, massage gently.', '<p>示範內容：個體差異存在，如有不適請停用並諮詢專業人士。</p>', '<p>Demo: discontinue if irritation occurs.</p>', 'knowledge', '護理實驗室', UNIX_TIMESTAMP());

INSERT INTO `news` (`title`, `title_en`, `summary`, `summary_en`, `content`, `content_en`, `type`, `icon`, `source`, `created_at`) VALUES
('乾燥季如何疊塗身體乳與精油', 'Layering lotion and oil in dry season', '先乳後油更鎖水，注意用量避免黏膩。', 'Lotion first, then oil; adjust amounts to avoid tackiness.', '<h3>步驟</h3><p>沐浴後趁角質含水，先塗身體乳再疊加少量身體油。</p>', '<h3>Steps</h3><p>After bathing, apply lotion then a little oil while skin is still hydrated.</p>', 'knowledge', 'ri-drop-line', 'CocoBrite 實驗室', UNIX_TIMESTAMP()),
('美白身體乳可以塗臉嗎', 'Can I use body lotion on my face', '通常不建議，面部角質與耐受與身體肌膚不同。', 'Generally not recommended; facial skin differs.', '<p>身體乳僅供身體使用；面部請選面部專用產品。</p>', '<p>Body lotions are for the body; use face-specific products on the face.</p>', 'knowledge', 'ri-information-line', NULL, UNIX_TIMESTAMP()),
('果酸身體乳入門：頻率與防曬', 'AHA body lotion basics: frequency & SPF', '溫和起步，循序漸進，白天注意防曬。', 'Start slow; use sunscreen by day.', '<p>敏感肌先局部測試；出現刺痛紅腫請停用。</p>', '<p>Patch test if sensitive; stop if stinging or redness.</p>', 'knowledge', 'ri-sun-line', NULL, UNIX_TIMESTAMP()),
('香氛身體乳留香小技巧', 'Tips to make scented lotion last', '可輕點同款香氛於脈搏點，層次更自然。', 'Dab matching fragrance on pulse points.', '<p>示範內容：香氛濃度因個人喜好調整。</p>', '<p>Demo: adjust fragrance strength to taste.</p>', 'knowledge', 'ri-flask-line', NULL, UNIX_TIMESTAMP()),
('身體美白的常見誤區', 'Common myths about body brightening', '角質層健康與保濕是光澤感前提。', 'Healthy barrier + hydration first.', '<p>化妝品功效宣稱以標籤為準；效果因人而異。</p>', '<p>Claims follow labeling; results vary.</p>', 'knowledge', 'ri-book-open-line', NULL, UNIX_TIMESTAMP());

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
