-- 雙語欄位（既有 MySQL 庫執行一次）
ALTER TABLE `product_categories` ADD COLUMN `name_en` varchar(100) DEFAULT NULL COMMENT '英文名稱' AFTER `name`;

ALTER TABLE `products` ADD COLUMN `name_en` varchar(255) DEFAULT NULL COMMENT '英文品名' AFTER `name`;
ALTER TABLE `products` ADD COLUMN `description_en` text COMMENT '英文描述' AFTER `description`;

ALTER TABLE `news` ADD COLUMN `title_en` varchar(255) DEFAULT NULL COMMENT '英文標題' AFTER `title`;
ALTER TABLE `news` ADD COLUMN `summary_en` varchar(500) DEFAULT NULL COMMENT '英文摘要' AFTER `summary`;
ALTER TABLE `news` ADD COLUMN `content_en` longtext COMMENT '英文內容' AFTER `content`;
