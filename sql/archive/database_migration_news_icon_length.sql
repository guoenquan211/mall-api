-- 扩展 news.icon 字段以支持上传图片 URL（MySQL）
ALTER TABLE `news` MODIFY COLUMN `icon` varchar(512) DEFAULT NULL COMMENT '图标class或图片URL(科普类)';
