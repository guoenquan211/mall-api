-- CocoBrite 演示数据（MySQL）
-- 会删除订单、收藏、商品、分类、资讯，执行前请备份。

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;
DELETE FROM order_items;
DELETE FROM orders;
DELETE FROM commission_records;
DELETE FROM user_favorites;
DELETE FROM product_images;
DELETE FROM product_variants;
DELETE FROM products;
DELETE FROM product_categories;
DELETE FROM news;
SET FOREIGN_KEY_CHECKS = 1;

INSERT INTO `admin_users` (`username`, `password`, `nickname`, `role`, `created_at`) VALUES
('admin', '$2y$10$abcdefg...', '超级管理员', 'super_admin', UNIX_TIMESTAMP())
ON DUPLICATE KEY UPDATE `username` = `username`;

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
('user001', '$2y$10$hijklmn...', '身体护理爱好者', UNIX_TIMESTAMP())
ON DUPLICATE KEY UPDATE `username` = `username`;
