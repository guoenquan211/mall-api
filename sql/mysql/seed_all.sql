-- CocoBrite 全站演示数据（MySQL）
-- 适用：已导入 schema_full.sql 的空库
-- ⚠ 请整份 SQL 一次性执行（不要逐条运行）
-- 账号：后台 admin/As741293@123  前台 user001、user002/User123456

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

DELETE FROM `commission_records`;
DELETE FROM `withdrawal_requests`;
DELETE FROM `order_items`;
DELETE FROM `orders`;
DELETE FROM `user_favorites`;
DELETE FROM `user_addresses`;
DELETE FROM `user_logs`;
DELETE FROM `user_affiliate_stats`;
DELETE FROM `contact_messages`;
DELETE FROM `product_images`;
DELETE FROM `product_variants`;
DELETE FROM `products`;
DELETE FROM `product_categories`;
DELETE FROM `news`;
DELETE FROM `users`;

-- 重置自增 ID（DELETE 后可选）
ALTER TABLE `products` AUTO_INCREMENT = 1;
ALTER TABLE `product_variants` AUTO_INCREMENT = 1;
ALTER TABLE `orders` AUTO_INCREMENT = 1;
ALTER TABLE `users` AUTO_INCREMENT = 1;
ALTER TABLE `news` AUTO_INCREMENT = 1;

-- ── 管理员 ─────────────────────────────────────────
INSERT INTO `admin_users` (`username`, `password`, `nickname`, `role`, `status`, `created_at`, `updated_at`) VALUES
('admin', '$2b$10$8Ar.tYBg727J8cXnA2I19OCedEGoc9o17.s0X.tY2Xsw6N.RGNFbS', '超级管理员', 'super_admin', 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP())
ON DUPLICATE KEY UPDATE
  `password` = VALUES(`password`), `nickname` = VALUES(`nickname`), `role` = VALUES(`role`), `status` = 1, `updated_at` = UNIX_TIMESTAMP();

-- ── 商品分类 ───────────────────────────────────────
INSERT INTO `product_categories` (`id`, `name`, `name_en`, `sort_order`, `status`, `created_at`, `updated_at`) VALUES
(1, '身體護理', 'Body care', 10, 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
(2, '香氛身體乳', 'Scented body lotion', 20, 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
(3, '手足護理', 'Hand & foot care', 30, 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
(4, '沐浴', 'Bath', 40, 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
(5, '禮盒', 'Gift sets', 50, 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP());

-- ── 商品（category 须与 product_categories.name 一致）──
INSERT INTO `products` (`id`, `name`, `name_en`, `category`, `description`, `description_en`, `price`, `image`, `stock`, `status`, `show_on_home`, `created_at`, `updated_at`) VALUES
(1, 'CocoBrite 光感美白身體乳', 'CocoBrite Radiance Body Lotion', '身體護理',
 '煙醯胺與透明質酸協同，輕盈乳液質地，易吸收不假滑。實際效果因人而異。',
 'Niacinamide and hyaluronic acid in a lightweight lotion. Individual results may vary.',
 168.00, '/images/stock/lotion.jpg', 200, 1, 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
(2, 'CocoBrite 梔子花香氛身體乳', 'CocoBrite Gardenia Body Lotion', '香氛身體乳',
 '淡雅花香，保濕潤澤，適合日常浴後護理。',
 'Soft floral scent with daily moisturizing after bathing.',
 128.00, '/images/stock/tube.jpg', 150, 1, 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
(3, 'CocoBrite 果酸柔滑身體乳', 'CocoBrite AHA Smoothing Lotion', '身體護理',
 '溫和果酸，幫助改善粗糙角質（敏感肌請先局部測試）。',
 'Gentle AHAs for rough texture. Patch test if sensitive.',
 158.00, '/images/stock/spa.jpg', 90, 1, 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
(4, 'CocoBrite 維C亮采護手霜', 'CocoBrite Vitamin C Hand Cream', '手足護理',
 '小巧便攜，手部保濕提亮。',
 'Travel-friendly hand hydration and brightening.',
 48.00, '/images/stock/tube.jpg', 300, 1, 0, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
(5, 'CocoBrite 身體精華油', 'CocoBrite Body Serum Oil', '身體護理',
 '以油養膚，浴後按摩使用，滋潤不黏膩。',
 'Oil-rich care for post-bath massage without greasiness.',
 188.00, '/images/stock/lotion.jpg', 60, 1, 0, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
(6, 'CocoBrite 沐浴慕斯', 'CocoBrite Bath Mousse', '沐浴',
 '綿密泡沫，溫和清潔，洗後不緊繃。',
 'Rich foam, gentle cleanse, comfortable after rinse.',
 88.00, '/images/stock/spa.jpg', 120, 1, 0, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
(7, 'CocoBrite 磨砂膏（椰奶香）', 'CocoBrite Body Scrub (Coconut)', '身體護理',
 '細膩顆粒，關節暗沉部位輕柔打圈使用。',
 'Fine grains; gently buff dull areas.',
 118.00, '/images/stock/spa.jpg', 75, 1, 0, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
(8, 'CocoBrite 旅行裝四件套', 'CocoBrite Travel Set (4 pcs)', '禮盒',
 '身體乳+沐浴+手霜+髮膜小樣，出差旅行常備。',
 'Lotion, bath, hand cream & hair mask minis for travel.',
 99.00, '/images/stock/tube.jpg', 200, 1, 0, UNIX_TIMESTAMP(), UNIX_TIMESTAMP());

INSERT INTO `product_variants` (`product_id`, `name`, `price`, `stock`, `created_at`) VALUES
(1, '400ml 家庭装', 168.00, 120, UNIX_TIMESTAMP()),
(1, '200ml 便携装', 98.00, 80, UNIX_TIMESTAMP()),
(2, '300ml', 128.00, 100, UNIX_TIMESTAMP()),
(2, '300ml 双支礼盒', 238.00, 50, UNIX_TIMESTAMP()),
(3, '300ml', 158.00, 90, UNIX_TIMESTAMP());

INSERT INTO `product_images` (`product_id`, `image`, `sort`, `created_at`) VALUES
(1, '/images/stock/lotion.jpg', 0, UNIX_TIMESTAMP()),
(1, '/images/stock/spa.jpg', 1, UNIX_TIMESTAMP()),
(2, '/images/stock/tube.jpg', 0, UNIX_TIMESTAMP()),
(3, '/images/stock/spa.jpg', 0, UNIX_TIMESTAMP());

-- ── 品牌资讯（type=news）────────────────────────────
INSERT INTO `news` (`title`, `title_en`, `summary`, `summary_en`, `content`, `content_en`, `type`, `cover_image`, `date`, `source`, `created_at`) VALUES
('CocoBrite 光感系列全新升級上市', 'CocoBrite Radiance Line Relaunch',
 '在保留經典配方的基礎上，優化乳化體系與膚感，帶來更輕盈的塗抹體驗。',
 'A lighter texture with the same trusted formula philosophy.',
 '<p>新品已在官網與合作渠道同步上架，產品信息以包裝標註為準。</p>',
 '<p>Now available online. See packaging for local labeling requirements.</p>',
 'news', '/images/stock/lotion.jpg', '2026.03.15', 'CocoBrite 品牌部', UNIX_TIMESTAMP()),
('「以光養膚」主題快閃店登陸馬尼拉 BGC', 'CocoBrite Pop-up in Manila BGC',
 '現場可體驗身體乳質地測試、香氛小課堂，完成打卡即可獲得小樣禮贈。',
 'Texture tests, scent workshops, and sample gifts for visitors.',
 '<p>活動時間與地址請關注官方社群公告。</p>',
 '<p>Follow our social channels for dates and venue details.</p>',
 'news', '/images/stock/hero.jpg', '2026.03.10', '市場部', UNIX_TIMESTAMP()),
('春季身體護理：浴後黃金 3 分鐘', 'Spring Body Care: 3 Minutes After Bath',
 '浴後毛孔微張時塗抹身體乳，有助於提升保濕感受。乾性肌膚可疊加精華油。',
 'Apply lotion while skin is still slightly damp for better hydration.',
 '<p>建議配合溫和沐浴，避免水溫過高。</p>',
 '<p>Use lukewarm water and a gentle cleanser.</p>',
 'news', '/images/stock/spa.jpg', '2026.03.05', '護膚顧問團', UNIX_TIMESTAMP()),
('CocoBrite 發布《身體美白護理白皮書》', 'Body Brightening Care White Paper',
 '從角質管理、保濕、防曬協同等維度，科普理性護理觀念（非醫療建議）。',
 'Education on barrier care, hydration, and sun protection — not medical advice.',
 '<p>完整 PDF 可在官網「品牌動態」下載。</p>',
 '<p>Download the summary from our News section.</p>',
 'news', '/images/stock/tube.jpg', '2026.02.28', '品牌合作媒體', UNIX_TIMESTAMP()),
('會員日預告：滿贈身體乳中樣', 'Member Day: Free Travel-size Lotion',
 '每月 18 日會員專享，具體規則以活動頁公示為準。',
 'Monthly member offers — see the promo page for terms.',
 '<p>註冊會員即可收到開賣提醒。</p>',
 '<p>Register to get event reminders.</p>',
 'news', '/images/stock/lotion.jpg', '2026.02.20', '電商運營', UNIX_TIMESTAMP());

-- ── 美護科普（type=knowledge）────────────────────────
INSERT INTO `news` (`title`, `title_en`, `summary`, `summary_en`, `content`, `content_en`, `type`, `icon`, `source`, `created_at`) VALUES
('身體乳怎麼塗才不算「白塗」？', 'How to apply body lotion effectively',
 '用量、順序與按摩手法，決定保濕與光澤感。',
 'Amount, order, and massage technique matter.',
 '<h3>1. 用量</h3><p>四肢單次約 2～3 元硬幣大小，乾燥季可略增。</p><h3>2. 時機</h3><p>沐浴後輕擦至微潤時塗抹最佳。</p>',
 '<h3>Amount</h3><p>Use enough to cover without streaking.</p><h3>Timing</h3><p>Apply while skin is still slightly damp.</p>',
 'knowledge', 'ri-drop-line', 'CocoBrite 美護課堂', UNIX_TIMESTAMP()),
('煙醯胺身體乳：建立耐受小貼士', 'Niacinamide lotion: building tolerance',
 '從低頻次、小面積開始，觀察皮膚狀態。',
 'Start small and increase gradually.',
 '<p>避免與高濃度果酸、A 醇同晚疊涂同一部位。</p>',
 '<p>Avoid stacking with strong retinoids on the same night.</p>',
 'knowledge', 'ri-flask-line', 'CocoBrite 實驗室', UNIX_TIMESTAMP()),
('雞皮膚（毛周角化）日常護理思路', 'Keratosis pilaris: daily care',
 '溫和去角質 + 保濕為主，勿過度摩擦。',
 'Gentle exfoliation plus hydration.',
 '<p>含果酸或尿素類身體乳可幫助平滑膚質，從低濃度開始。</p>',
 '<p>Low-strength AHA or urea body lotions may help over time.</p>',
 'knowledge', 'ri-hand-heart-line', NULL, UNIX_TIMESTAMP()),
('香氛身體乳：如何讓留香更自然？', 'Scented lotion: lasting fragrance tips',
 '疊香與用量控制，避免與香水「打架」。',
 'Layer scents lightly for a natural finish.',
 '<p>沐浴與身體乳選相近香調，層次更協調。</p>',
 '<p>Match bath and lotion fragrance families.</p>',
 'knowledge', 'ri-leaf-line', NULL, UNIX_TIMESTAMP()),
('美白化妝品合規提示（消費者必讀）', 'Brightening claims: consumer guide',
 '了解「美白」宣稱的監管要求，理性選購。',
 'Regulations vary by market — read the label.',
 '<p>不存在適用於所有人的承諾效果，請通過正規渠道購買。</p>',
 '<p>Results vary. Buy from authorized retailers.</p>',
 'knowledge', 'ri-shield-check-line', NULL, UNIX_TIMESTAMP()),
('旅行裝箱：身體護理極簡清單', 'Travel body-care packing list',
 '小容量與多效合一，減輕行李負擔。',
 'Minis and multi-use products save space.',
 '<p>必備：便携身體乳、溫和沐浴、防曬（暴露部位）。</p>',
 '<p>Pack lotion, gentle wash, and SPF for exposed skin.</p>',
 'knowledge', 'ri-suitcase-line', NULL, UNIX_TIMESTAMP());

-- ── 前台会员（密码均为 User123456）──────────────────
INSERT INTO `users` (`id`, `username`, `password`, `nickname`, `phone`, `email`, `points`, `invite_code`, `parent_id`, `affiliate_level`, `locale`, `status`, `created_at`, `updated_at`) VALUES
(1, 'user001', '$2b$10$Alx7oncmhJ0WxV1vUUMcAOOaoiRBeGoC2.MZSjYLY1mhAgzVwdvBe', 'Anna', '09171234567', 'anna@example.com', 120, 'CB8K2M', NULL, 1, 'zh-TW', 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
(2, 'user002', '$2b$10$Alx7oncmhJ0WxV1vUUMcAOOaoiRBeGoC2.MZSjYLY1mhAgzVwdvBe', 'Ben', '09187654321', 'ben@example.com', 50, 'CB9P3N', 1, 0, 'en', 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP());

INSERT INTO `user_addresses` (`user_id`, `name`, `phone`, `province`, `city`, `district`, `detail`, `is_default`, `created_at`, `updated_at`) VALUES
(1, 'Anna Chen', '09171234567', 'Metro Manila', 'Taguig', 'BGC', 'Unit 1208, High Street South Corporate Plaza', 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
(2, 'Ben Santos', '09187654321', 'Metro Manila', 'Makati', 'Poblacion', 'Legazpi Village, Building 5', 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP());

INSERT INTO `user_affiliate_stats` (`user_id`, `downline_pv_total`, `updated_at`) VALUES
(1, 1280.00, UNIX_TIMESTAMP());

-- ── 示例订单（后台订单管理可见）────────────────────
INSERT INTO `orders` (`id`, `order_no`, `user_id`, `total_amount`, `goods_amount`, `status`, `payment_method`, `payment_status`, `paid_at`, `address_snapshot`, `remark`, `created_at`, `updated_at`) VALUES
(1, 'ORD20260325143000', 1, 168.00, 168.00, 3, 'gcash', 'approved', UNIX_TIMESTAMP() - 86400,
 '{"name":"Anna Chen","phone":"09171234567","detail":"Unit 1208, BGC, Taguig"}', '请尽快发货', UNIX_TIMESTAMP() - 86400 * 2, UNIX_TIMESTAMP()),
(2, 'ORD20260325150000', 2, 128.00, 128.00, 1, 'gcash', 'approved', UNIX_TIMESTAMP() - 3600,
 '{"name":"Ben Santos","phone":"09187654321","detail":"Legazpi Village, Makati"}', NULL, UNIX_TIMESTAMP() - 7200, UNIX_TIMESTAMP()),
(3, 'ORD20260325153000', 1, 98.00, 98.00, 0, 'gcash', 'pending', NULL,
 '{"name":"Anna Chen","phone":"09171234567","detail":"Unit 1208, BGC, Taguig"}', NULL, UNIX_TIMESTAMP(), UNIX_TIMESTAMP());

INSERT INTO `order_items` (`order_id`, `product_id`, `variant_id`, `product_name`, `product_image`, `variant_name`, `price`, `quantity`) VALUES
(1, 1, 1, 'CocoBrite 光感美白身體乳', '/images/stock/lotion.jpg', '400ml 家庭装', 168.00, 1),
(2, 2, 3, 'CocoBrite 梔子花香氛身體乳', '/images/stock/tube.jpg', '300ml', 128.00, 1),
(3, 1, 2, 'CocoBrite 光感美白身體乳', '/images/stock/lotion.jpg', '200ml 便携装', 98.00, 1);

-- ── 联络留言（后台可见）────────────────────────────
INSERT INTO `contact_messages` (`visitor_name`, `contact`, `content`, `locale`, `ip`, `status`, `created_at`, `updated_at`) VALUES
('Maria', 'maria@example.com', '请问光感身体乳是否适合敏感肌？', 'zh-TW', '127.0.0.1', 0, UNIX_TIMESTAMP() - 3600, UNIX_TIMESTAMP() - 3600),
('John', 'john@example.com', 'Do you ship to Cebu?', 'en', '127.0.0.1', 0, UNIX_TIMESTAMP() - 1800, UNIX_TIMESTAMP() - 1800);

-- ── GCash 收款账号（后台 GCash 管理）────────────────
UPDATE `gcash_platform_accounts` SET
  `label` = 'CocoBrite GCash 主账号',
  `account_name` = 'CocoBrite Beauty',
  `mobile` = '09170000001',
  `is_active` = 1,
  `updated_at` = UNIX_TIMESTAMP()
WHERE `slot` = 1;

UPDATE `gcash_platform_accounts` SET
  `label` = 'CocoBrite GCash 备用',
  `account_name` = 'CocoBrite Store',
  `mobile` = '09170000002',
  `is_active` = 1,
  `updated_at` = UNIX_TIMESTAMP()
WHERE `slot` = 2;

SET FOREIGN_KEY_CHECKS = 1;
