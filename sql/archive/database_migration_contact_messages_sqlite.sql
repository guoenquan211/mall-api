-- SQLite: 前台聯絡留言表
CREATE TABLE IF NOT EXISTS `contact_messages` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `visitor_name` TEXT NOT NULL,
  `contact` TEXT DEFAULT NULL,
  `content` TEXT NOT NULL,
  `locale` TEXT NOT NULL DEFAULT 'zh-TW',
  `ip` TEXT DEFAULT NULL,
  `status` INTEGER NOT NULL DEFAULT 0,
  `created_at` INTEGER DEFAULT NULL,
  `updated_at` INTEGER DEFAULT NULL
);
