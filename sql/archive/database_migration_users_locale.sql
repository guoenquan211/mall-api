-- MySQL / MariaDB：使用者介面語系（前台 X-Locale / 註冊偏好）
ALTER TABLE `users`
  ADD COLUMN `locale` varchar(16) NOT NULL DEFAULT 'zh-TW' COMMENT 'zh-TW|en' AFTER `status`;
