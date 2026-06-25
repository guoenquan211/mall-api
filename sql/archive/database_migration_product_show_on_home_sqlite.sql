-- SQLite：为已有库增加列（新库请直接用更新后的 database_sqlite.sql）
ALTER TABLE `products` ADD COLUMN `show_on_home` INTEGER NOT NULL DEFAULT 0;
