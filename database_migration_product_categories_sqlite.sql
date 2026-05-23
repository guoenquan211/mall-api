-- 已有 SQLite 库升级：创建商品分类表并写入默认分类（可重复执行）。

CREATE TABLE IF NOT EXISTS `product_categories` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `name` TEXT NOT NULL UNIQUE,
  `sort_order` INTEGER NOT NULL DEFAULT 0,
  `status` INTEGER NOT NULL DEFAULT 1,
  `created_at` INTEGER DEFAULT NULL,
  `updated_at` INTEGER DEFAULT NULL
);

INSERT OR IGNORE INTO `product_categories` (`name`, `sort_order`, `status`, `created_at`, `updated_at`) VALUES
('身体护理', 10, 1, strftime('%s','now'), strftime('%s','now')),
('香氛身体乳', 20, 1, strftime('%s','now'), strftime('%s','now')),
('手足护理', 30, 1, strftime('%s','now'), strftime('%s','now')),
('沐浴', 40, 1, strftime('%s','now'), strftime('%s','now')),
('礼盒', 50, 1, strftime('%s','now'), strftime('%s','now'));
