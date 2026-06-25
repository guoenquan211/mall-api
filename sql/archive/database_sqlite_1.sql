
PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS `products` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `name` TEXT NOT NULL,
  `category` TEXT DEFAULT NULL,
  `description` TEXT,
  `price` REAL NOT NULL DEFAULT 0.00,
  `image` TEXT DEFAULT NULL,
  `stock` INTEGER NOT NULL DEFAULT 0,
  `status` INTEGER NOT NULL DEFAULT 1,
  `show_on_home` INTEGER NOT NULL DEFAULT 0,
  `created_at` INTEGER DEFAULT NULL,
  `updated_at` INTEGER DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS `product_categories` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `name` TEXT NOT NULL UNIQUE,
  `sort_order` INTEGER NOT NULL DEFAULT 0,
  `status` INTEGER NOT NULL DEFAULT 1,
  `created_at` INTEGER DEFAULT NULL,
  `updated_at` INTEGER DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS `product_variants` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `product_id` INTEGER NOT NULL,
  `name` TEXT NOT NULL,
  `price` REAL NOT NULL DEFAULT 0.00,
  `stock` INTEGER NOT NULL DEFAULT 0,
  `image` TEXT DEFAULT NULL,
  `created_at` INTEGER DEFAULT NULL,
  FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS `news` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `title` TEXT NOT NULL,
  `category` TEXT DEFAULT NULL,
  `summary` TEXT DEFAULT NULL,
  `content` TEXT,
  `type` TEXT NOT NULL DEFAULT 'news',
  `icon` TEXT DEFAULT NULL,
  `cover_image` TEXT DEFAULT NULL,
  `date` TEXT DEFAULT NULL,
  `source` TEXT DEFAULT NULL,
  `created_at` INTEGER DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS `product_images` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `product_id` INTEGER NOT NULL,
  `image` TEXT NOT NULL,
  `sort` INTEGER DEFAULT 0,
  `created_at` INTEGER DEFAULT NULL,
  FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS `users` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `username` TEXT NOT NULL UNIQUE,
  `password` TEXT NOT NULL,
  `nickname` TEXT DEFAULT NULL,
  `avatar` TEXT DEFAULT NULL,
  `phone` TEXT DEFAULT NULL,
  `email` TEXT DEFAULT NULL,
  `points` INTEGER DEFAULT 0,
  `status` INTEGER DEFAULT 1,
  `locale` TEXT NOT NULL DEFAULT 'zh-TW',
  `created_at` INTEGER DEFAULT NULL,
  `updated_at` INTEGER DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS `user_addresses` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `user_id` INTEGER NOT NULL,
  `name` TEXT NOT NULL,
  `phone` TEXT NOT NULL,
  `province` TEXT NOT NULL,
  `city` TEXT NOT NULL,
  `district` TEXT NOT NULL,
  `detail` TEXT NOT NULL,
  `is_default` INTEGER DEFAULT 0,
  `created_at` INTEGER DEFAULT NULL,
  `updated_at` INTEGER DEFAULT NULL,
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS `user_favorites` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `user_id` INTEGER NOT NULL,
  `product_id` INTEGER NOT NULL,
  `created_at` INTEGER DEFAULT NULL,
  UNIQUE (`user_id`, `product_id`),
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS `orders` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `order_no` TEXT NOT NULL UNIQUE,
  `user_id` INTEGER NOT NULL,
  `total_amount` REAL NOT NULL,
  `status` INTEGER DEFAULT 0,
  `express_company` TEXT DEFAULT NULL,
  `express_no` TEXT DEFAULT NULL,
  `address_snapshot` TEXT,
  `created_at` INTEGER DEFAULT NULL,
  `updated_at` INTEGER DEFAULT NULL,
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS `order_items` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `order_id` INTEGER NOT NULL,
  `product_id` INTEGER NOT NULL,
  `variant_id` INTEGER DEFAULT NULL,
  `product_name` TEXT NOT NULL,
  `product_image` TEXT DEFAULT NULL,
  `variant_name` TEXT DEFAULT NULL,
  `price` REAL NOT NULL,
  `quantity` INTEGER NOT NULL DEFAULT 1,
  FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS `admin_users` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `username` TEXT NOT NULL UNIQUE,
  `password` TEXT NOT NULL,
  `nickname` TEXT DEFAULT NULL,
  `role` TEXT DEFAULT 'admin',
  `avatar` TEXT DEFAULT NULL,
  `status` INTEGER DEFAULT 1,
  `last_login_at` INTEGER DEFAULT NULL,
  `created_at` INTEGER DEFAULT NULL,
  `updated_at` INTEGER DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS `admin_logs` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `admin_id` INTEGER NOT NULL,
  `action` TEXT NOT NULL,
  `target` TEXT DEFAULT NULL,
  `detail` TEXT DEFAULT NULL,
  `ip` TEXT DEFAULT NULL,
  `created_at` INTEGER DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS `contact_messages` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `visitor_name` TEXT NOT NULL,
  `contact` TEXT DEFAULT NULL,
  `content` TEXT NOT NULL,
  `locale` TEXT NOT NULL DEFAULT 'zh-TW',
  `ip` TEXT DEFAULT NULL,
  `status` INTEGER NOT NULL DEFAULT 0,
  `created_at` INTEGER DEFAULT NULL,
  `updated_at` INTEGER DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS `user_logs` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `user_id` INTEGER NOT NULL,
  `action` TEXT NOT NULL,
  `detail` TEXT DEFAULT NULL,
  `ip` TEXT DEFAULT NULL,
  `created_at` INTEGER DEFAULT NULL,
  `updated_at` INTEGER DEFAULT NULL
);

-- Insert Demo Data
INSERT INTO `admin_users` (`username`, `password`, `nickname`, `role`, `created_at`) VALUES
('admin', '$2y$10$abcdefg...', '超级管理员', 'super_admin', strftime('%s','now'));

INSERT INTO `product_categories` (`name`, `sort_order`, `status`, `created_at`, `updated_at`) VALUES
('身体护理', 10, 1, strftime('%s','now'), strftime('%s','now')),
('香氛身体乳', 20, 1, strftime('%s','now'), strftime('%s','now')),
('手足护理', 30, 1, strftime('%s','now'), strftime('%s','now')),
('沐浴', 40, 1, strftime('%s','now'), strftime('%s','now')),
('礼盒', 50, 1, strftime('%s','now'), strftime('%s','now'));

INSERT INTO `products` (`name`, `category`, `description`, `price`, `image`, `stock`, `status`, `show_on_home`, `created_at`) VALUES
('CocoBrite 光感美白身体乳', '身体护理', '烟酰胺与透明质酸协同，轻盈乳液质地，易吸收不假滑。实际效果因人而异。', 168.00, '/images/stock/lotion.jpg', 200, 1, 1, strftime('%s','now')),
('CocoBrite 栀子花香氛身体乳', '香氛身体乳', '淡雅花香，保湿润泽，适合日常浴后护理。', 128.00, '/images/stock/tube.jpg', 150, 1, 1, strftime('%s','now')),
('CocoBrite 果酸柔滑身体乳', '身体护理', '温和果酸，帮助改善粗糙角质（敏感肌请先局部测试）。', 158.00, '/images/stock/spa.jpg', 90, 1, 1, strftime('%s','now')),
('CocoBrite 维C亮采护手霜', '手足护理', '小巧便携，手部保湿提亮。', 48.00, '/images/stock/tube.jpg', 300, 1, 0, strftime('%s','now')),
('CocoBrite 身体精华油', '身体护理', '以油养肤，浴后按摩使用，滋润不黏腻。', 188.00, '/images/stock/lotion.jpg', 60, 1, 0, strftime('%s','now')),
('CocoBrite 沐浴慕斯', '沐浴', '绵密泡沫，温和清洁，洗后不紧绷。', 88.00, '/images/stock/spa.jpg', 120, 1, 0, strftime('%s','now')),
('CocoBrite 磨砂膏（椰奶香）', '身体护理', '细腻颗粒，关节暗沉部位轻柔打圈使用。', 118.00, '/images/stock/spa.jpg', 75, 1, 0, strftime('%s','now')),
('CocoBrite 旅行装四件套', '礼盒', '身体乳+沐浴+手霜+发膜小样，出差旅行常备。', 99.00, '/images/stock/tube.jpg', 200, 1, 0, strftime('%s','now'));

INSERT INTO `product_variants` (`product_id`, `name`, `price`, `stock`, `created_at`) VALUES
(1, '400ml 家庭装', 168.00, 120, strftime('%s','now')),
(1, '200ml 便携装', 98.00, 80, strftime('%s','now')),
(2, '300ml', 128.00, 100, strftime('%s','now')),
(2, '300ml 双支礼盒', 238.00, 50, strftime('%s','now'));

INSERT INTO `news` (`title`, `summary`, `content`, `type`, `source`, `created_at`) VALUES
('CocoBrite 光感美白身体乳焕新上市', '主打烟酰胺协同透明质酸，浴后三步护理更易坚持。', '<p>演示数据：新品与成分故事请以实物标签及备案信息为准。</p>', 'news', '品牌官方', strftime('%s','now')),
('浴后身体乳正确涂抹顺序', '先擦干水分再涂抹，关节处可略多涂，配合轻柔按摩促进吸收。', '<p>演示数据：个体差异存在，如有不适请停用并咨询专业人士。</p>', 'knowledge', '护理实验室', strftime('%s','now'));

INSERT INTO `news` (`title`, `summary`, `content`, `type`, `icon`, `source`, `created_at`) VALUES
('干燥季如何叠涂身体乳与精油', '先乳后油更锁水，注意用量避免黏腻。', '<h3>步骤</h3><p>沐浴后趁角质含水，先涂身体乳再叠加少量身体油。</p>', 'knowledge', 'ri-drop-line', 'CocoBrite 实验室', strftime('%s','now')),
('美白身体乳可以涂脸吗', '通常不建议，面部角质与耐受与身体肌肤不同。', '<p>身体乳仅供身体使用；面部请选面部专用产品。</p>', 'knowledge', 'ri-information-line', NULL, strftime('%s','now')),
('果酸身体乳入门：频率与防晒', '温和起步，循序渐进，白天注意防晒。', '<p>敏感肌先局部测试；出现刺痛红肿请停用。</p>', 'knowledge', 'ri-sun-line', NULL, strftime('%s','now')),
('香氛身体乳留香小技巧', '可轻点同款香氛于脉搏点，层次更自然。', '<p>演示内容：香氛浓度因个人喜好调整。</p>', 'knowledge', 'ri-flask-line', NULL, strftime('%s','now')),
('身体美白的常见误区', '角质层健康与保湿是光泽感前提。', '<p>化妆品功效宣称以标签为准；效果因人而异。</p>', 'knowledge', 'ri-book-open-line', NULL, strftime('%s','now'));

INSERT INTO `users` (`username`, `password`, `nickname`, `created_at`) VALUES
('user001', '$2y$10$hijklmn...', '身体护理爱好者', strftime('%s','now'));
