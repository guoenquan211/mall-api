-- SQLite 雙語欄位（既有庫執行一次）
ALTER TABLE `product_categories` ADD COLUMN `name_en` TEXT DEFAULT NULL;

ALTER TABLE `products` ADD COLUMN `name_en` TEXT DEFAULT NULL;
ALTER TABLE `products` ADD COLUMN `description_en` TEXT DEFAULT NULL;

ALTER TABLE `news` ADD COLUMN `title_en` TEXT DEFAULT NULL;
ALTER TABLE `news` ADD COLUMN `summary_en` TEXT DEFAULT NULL;
ALTER TABLE `news` ADD COLUMN `content_en` TEXT DEFAULT NULL;
