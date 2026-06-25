
PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS `products` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `name` TEXT NOT NULL,
  `name_en` TEXT DEFAULT NULL,
  `category` TEXT DEFAULT NULL,
  `description` TEXT,
  `description_en` TEXT,
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
  `name_en` TEXT DEFAULT NULL,
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
  `title_en` TEXT DEFAULT NULL,
  `category` TEXT DEFAULT NULL,
  `summary` TEXT DEFAULT NULL,
  `summary_en` TEXT DEFAULT NULL,
  `content` TEXT,
  `content_en` TEXT,
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
  `locale` TEXT NOT NULL DEFAULT 'en',
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

INSERT INTO `product_categories` (`name`, `name_en`, `sort_order`, `status`, `created_at`, `updated_at`) VALUES
('身體護理', 'Body care', 10, 1, strftime('%s','now'), strftime('%s','now')),
('香氛身體乳', 'Scented body lotion', 20, 1, strftime('%s','now'), strftime('%s','now')),
('手足護理', 'Hand & foot care', 30, 1, strftime('%s','now'), strftime('%s','now')),
('沐浴', 'Bath', 40, 1, strftime('%s','now'), strftime('%s','now')),
('禮盒', 'Gift sets', 50, 1, strftime('%s','now'), strftime('%s','now'));

INSERT INTO `products` (`name`, `name_en`, `category`, `description`, `description_en`, `price`, `image`, `stock`, `status`, `show_on_home`, `created_at`) VALUES
('CocoBrite 光感美白身體乳', 'CocoBrite Radiance Body Lotion', '身體護理', '煙醯胺與透明質酸協同，輕盈乳液質地，易吸收不假滑。實際效果因人而異。', 'Niacinamide and hyaluronic acid in a lightweight lotion. Individual results may vary.', 168.00, '/images/stock/lotion.jpg', 200, 1, 1, strftime('%s','now')),
('CocoBrite 梔子花香氛身體乳', 'CocoBrite Gardenia Body Lotion', '香氛身體乳', '淡雅花香，保濕潤澤，適合日常浴後護理。', 'Soft floral scent with daily moisturizing after bathing.', 128.00, '/images/stock/tube.jpg', 150, 1, 1, strftime('%s','now')),
('CocoBrite 果酸柔滑身體乳', 'CocoBrite AHA Smoothing Lotion', '身體護理', '溫和果酸，幫助改善粗糙角質（敏感肌請先局部測試）。', 'Gentle AHAs for rough texture. Patch test if sensitive.', 158.00, '/images/stock/spa.jpg', 90, 1, 1, strftime('%s','now')),
('CocoBrite 維C亮采護手霜', 'CocoBrite Vitamin C Hand Cream', '手足護理', '小巧便攜，手部保濕提亮。', 'Travel-friendly hand hydration and brightening.', 48.00, '/images/stock/tube.jpg', 300, 1, 0, strftime('%s','now')),
('CocoBrite 身體精華油', 'CocoBrite Body Serum Oil', '身體護理', '以油養膚，浴後按摩使用，滋潤不黏膩。', 'Oil-rich care for post-bath massage without greasiness.', 188.00, '/images/stock/lotion.jpg', 60, 1, 0, strftime('%s','now')),
('CocoBrite 沐浴慕斯', 'CocoBrite Bath Mousse', '沐浴', '綿密泡沫，溫和清潔，洗後不緊繃。', 'Rich foam, gentle cleanse, comfortable after rinse.', 88.00, '/images/stock/spa.jpg', 120, 1, 0, strftime('%s','now')),
('CocoBrite 磨砂膏（椰奶香）', 'CocoBrite Body Scrub (Coconut)', '身體護理', '細膩顆粒，關節暗沉部位輕柔打圈使用。', 'Fine grains; gently buff dull areas.', 118.00, '/images/stock/spa.jpg', 75, 1, 0, strftime('%s','now')),
('CocoBrite 旅行裝四件套', 'CocoBrite Travel Set (4 pcs)', '禮盒', '身體乳+沐浴+手霜+髮膜小樣，出差旅行常備。', 'Lotion, bath, hand cream & hair mask minis for travel.', 99.00, '/images/stock/tube.jpg', 200, 1, 0, strftime('%s','now'));

INSERT INTO `product_variants` (`product_id`, `name`, `price`, `stock`, `created_at`) VALUES
(1, '400ml 家庭装', 168.00, 120, strftime('%s','now')),
(1, '200ml 便携装', 98.00, 80, strftime('%s','now')),
(2, '300ml', 128.00, 100, strftime('%s','now')),
(2, '300ml 双支礼盒', 238.00, 50, strftime('%s','now'));

INSERT INTO `news` (`title`, `title_en`, `summary`, `summary_en`, `content`, `content_en`, `type`, `source`, `created_at`) VALUES
('CocoBrite 光感美白身體乳煥新上市', 'CocoBrite Radiance Body Lotion Launch', '主打煙醯胺協同透明質酸，浴後三步護理更易堅持。', 'Niacinamide + HA and a simple 3-step after-bath routine.', '<p>示範內容：新品與成分故事請以實物標籤及備案資訊為準。</p>', '<p>Demo copy; see packaging and local regulations for claims.</p>', 'news', '品牌官方', strftime('%s','now')),
('浴後身體乳正確塗抹順序', 'How to apply body lotion after bathing', '先擦乾水分再塗抹，關節處可略多塗，配合輕柔按摩促進吸收。', 'Pat dry, apply more on joints, massage gently.', '<p>示範內容：個體差異存在，如有不適請停用並諮詢專業人士。</p>', '<p>Demo: discontinue if irritation occurs.</p>', 'knowledge', '護理實驗室', strftime('%s','now'));

INSERT INTO `news` (`title`, `title_en`, `summary`, `summary_en`, `content`, `content_en`, `type`, `icon`, `source`, `created_at`) VALUES
('乾燥季如何疊塗身體乳與精油', 'Layering lotion and oil in dry season', '先乳後油更鎖水，注意用量避免黏膩。', 'Lotion first, then oil; adjust amounts to avoid tackiness.', '<h3>步驟</h3><p>沐浴後趁角質含水，先塗身體乳再疊加少量身體油。</p>', '<h3>Steps</h3><p>After bathing, apply lotion then a little oil while skin is still hydrated.</p>', 'knowledge', 'ri-drop-line', 'CocoBrite 實驗室', strftime('%s','now')),
('美白身體乳可以塗臉嗎', 'Can I use body lotion on my face', '通常不建議，面部角質與耐受與身體肌膚不同。', 'Generally not recommended; facial skin differs.', '<p>身體乳僅供身體使用；面部請選面部專用產品。</p>', '<p>Body lotions are for the body; use face-specific products on the face.</p>', 'knowledge', 'ri-information-line', NULL, strftime('%s','now')),
('果酸身體乳入門：頻率與防曬', 'AHA body lotion basics: frequency & SPF', '溫和起步，循序漸進，白天注意防曬。', 'Start slow; use sunscreen by day.', '<p>敏感肌先局部測試；出現刺痛紅腫請停用。</p>', '<p>Patch test if sensitive; stop if stinging or redness.</p>', 'knowledge', 'ri-sun-line', NULL, strftime('%s','now')),
('香氛身體乳留香小技巧', 'Tips to make scented lotion last', '可輕點同款香氛於脈搏點，層次更自然。', 'Dab matching fragrance on pulse points.', '<p>示範內容：香氛濃度因個人喜好調整。</p>', '<p>Demo: adjust fragrance strength to taste.</p>', 'knowledge', 'ri-flask-line', NULL, strftime('%s','now')),
('身體美白的常見誤區', 'Common myths about body brightening', '角質層健康與保濕是光澤感前提。', 'Healthy barrier + hydration first.', '<p>化妝品功效宣稱以標籤為準；效果因人而異。</p>', '<p>Claims follow labeling; results vary.</p>', 'knowledge', 'ri-book-open-line', NULL, strftime('%s','now'));

INSERT INTO `users` (`username`, `password`, `nickname`, `created_at`) VALUES
('user001', '$2y$10$hijklmn...', '身体护理爱好者', strftime('%s','now'));
