-- CocoBrite：清空旧商品/资讯并写入与 database.sql 一致的演示数据（MySQL）。
-- 会删除订单与收藏关联，执行前请备份数据库。

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;
DELETE FROM order_items;
DELETE FROM orders;
DELETE FROM user_favorites;
DELETE FROM product_images;
DELETE FROM product_variants;
DELETE FROM products;
DELETE FROM product_categories;
DELETE FROM news;
SET FOREIGN_KEY_CHECKS = 1;

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
