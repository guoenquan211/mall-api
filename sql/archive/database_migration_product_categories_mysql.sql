-- 已有库升级：创建商品分类表并写入默认分类（可重复执行）。
-- MySQL

SET NAMES utf8mb4;

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

INSERT IGNORE INTO `product_categories` (`name`, `sort_order`, `status`, `created_at`, `updated_at`) VALUES
('身体护理', 10, 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
('香氛身体乳', 20, 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
('手足护理', 30, 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
('沐浴', 40, 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
('礼盒', 50, 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP());
