-- CocoBrite mall-api 完整库结构（SQLite）
-- 用途：本地开发新建库时执行一次。演示数据请另导 sql/sqlite/seed_demo.sql

PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS `products` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `name` TEXT NOT NULL,
  `name_en` TEXT DEFAULT NULL,
  `category` TEXT DEFAULT NULL,
  `description` TEXT,
  `description_en` TEXT,
  `price` REAL NOT NULL DEFAULT 0.00,
  `image` TEXT DEFAULT NULL,
  `stock` INTEGER NOT NULL DEFAULT 0,
  `status` INTEGER NOT NULL DEFAULT 1,
  `show_on_home` INTEGER NOT NULL DEFAULT 0,
  `created_at` INTEGER DEFAULT NULL,
  `updated_at` INTEGER DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS `product_categories` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `name` TEXT NOT NULL UNIQUE,
  `name_en` TEXT DEFAULT NULL,
  `sort_order` INTEGER NOT NULL DEFAULT 0,
  `status` INTEGER NOT NULL DEFAULT 1,
  `created_at` INTEGER DEFAULT NULL,
  `updated_at` INTEGER DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS `product_variants` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `product_id` INTEGER NOT NULL,
  `name` TEXT NOT NULL,
  `price` REAL NOT NULL DEFAULT 0.00,
  `stock` INTEGER NOT NULL DEFAULT 0,
  `image` TEXT DEFAULT NULL,
  `created_at` INTEGER DEFAULT NULL,
  FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS `news` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `title` TEXT NOT NULL,
  `title_en` TEXT DEFAULT NULL,
  `category` TEXT DEFAULT NULL,
  `summary` TEXT DEFAULT NULL,
  `summary_en` TEXT DEFAULT NULL,
  `content` TEXT,
  `content_en` TEXT,
  `type` TEXT NOT NULL DEFAULT 'news',
  `icon` TEXT DEFAULT NULL,
  `cover_image` TEXT DEFAULT NULL,
  `date` TEXT DEFAULT NULL,
  `source` TEXT DEFAULT NULL,
  `created_at` INTEGER DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS `product_images` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `product_id` INTEGER NOT NULL,
  `image` TEXT NOT NULL,
  `sort` INTEGER DEFAULT 0,
  `created_at` INTEGER DEFAULT NULL,
  FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS `users` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `username` TEXT NOT NULL UNIQUE,
  `password` TEXT NOT NULL,
  `nickname` TEXT DEFAULT NULL,
  `avatar` TEXT DEFAULT NULL,
  `phone` TEXT DEFAULT NULL,
  `email` TEXT DEFAULT NULL,
  `points` INTEGER DEFAULT 0,
  `invite_code` TEXT DEFAULT NULL,
  `parent_id` INTEGER DEFAULT NULL,
  `affiliate_level` INTEGER NOT NULL DEFAULT 0,
  `total_paid_goods` REAL NOT NULL DEFAULT 0,
  `gcash_number` TEXT DEFAULT NULL,
  `gcash_name` TEXT DEFAULT NULL,
  `status` INTEGER DEFAULT 1,
  `locale` TEXT NOT NULL DEFAULT 'zh-TW',
  `created_at` INTEGER DEFAULT NULL,
  `updated_at` INTEGER DEFAULT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS `uk_users_invite_code` ON `users` (`invite_code`);
CREATE INDEX IF NOT EXISTS `idx_users_parent` ON `users` (`parent_id`);

CREATE TABLE IF NOT EXISTS `user_addresses` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `user_id` INTEGER NOT NULL,
  `name` TEXT NOT NULL,
  `phone` TEXT NOT NULL,
  `province` TEXT NOT NULL,
  `city` TEXT NOT NULL,
  `district` TEXT NOT NULL,
  `detail` TEXT NOT NULL,
  `is_default` INTEGER DEFAULT 0,
  `created_at` INTEGER DEFAULT NULL,
  `updated_at` INTEGER DEFAULT NULL,
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS `user_favorites` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `user_id` INTEGER NOT NULL,
  `product_id` INTEGER NOT NULL,
  `created_at` INTEGER DEFAULT NULL,
  UNIQUE (`user_id`, `product_id`),
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS `orders` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `order_no` TEXT NOT NULL UNIQUE,
  `user_id` INTEGER NOT NULL,
  `total_amount` REAL NOT NULL,
  `goods_amount` REAL NOT NULL DEFAULT 0,
  `status` INTEGER DEFAULT 0,
  `payment_method` TEXT NOT NULL DEFAULT 'gcash',
  `payment_status` TEXT NOT NULL DEFAULT 'pending',
  `payment_account_slot` INTEGER DEFAULT NULL,
  `user_paid_at` INTEGER DEFAULT NULL,
  `payment_remark` TEXT DEFAULT NULL,
  `payment_proof_image` TEXT DEFAULT NULL,
  `payment_reject_reason` TEXT DEFAULT NULL,
  `paid_at` INTEGER DEFAULT NULL,
  `confirmed_at` INTEGER DEFAULT NULL,
  `b1_user_id` INTEGER DEFAULT NULL,
  `b2_user_id` INTEGER DEFAULT NULL,
  `b3_user_id` INTEGER DEFAULT NULL,
  `express_company` TEXT DEFAULT NULL,
  `express_no` TEXT DEFAULT NULL,
  `address_snapshot` TEXT,
  `remark` TEXT DEFAULT NULL,
  `created_at` INTEGER DEFAULT NULL,
  `updated_at` INTEGER DEFAULT NULL,
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS `order_items` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `order_id` INTEGER NOT NULL,
  `product_id` INTEGER NOT NULL,
  `variant_id` INTEGER DEFAULT NULL,
  `product_name` TEXT NOT NULL,
  `product_image` TEXT DEFAULT NULL,
  `variant_name` TEXT DEFAULT NULL,
  `price` REAL NOT NULL,
  `quantity` INTEGER NOT NULL DEFAULT 1,
  FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS `affiliate_program_config` (
  `id` INTEGER NOT NULL DEFAULT 1 PRIMARY KEY,
  `currency_suffix` TEXT NOT NULL DEFAULT 'P',
  `level1_name` TEXT NOT NULL DEFAULT '美妆分享官',
  `level2_name` TEXT NOT NULL DEFAULT '美妆达人',
  `level3_name` TEXT NOT NULL DEFAULT '美妆合伙人',
  `level1_spend_threshold` REAL NOT NULL DEFAULT 1000,
  `level1_any_order` INTEGER NOT NULL DEFAULT 1,
  `level2_direct_l1_min` INTEGER NOT NULL DEFAULT 5,
  `level2_team_pv` REAL NOT NULL DEFAULT 5000,
  `level3_direct_l2_min` INTEGER NOT NULL DEFAULT 3,
  `level3_team_pv` REAL NOT NULL DEFAULT 20000,
  `commission_rate_1` REAL NOT NULL DEFAULT 0.2,
  `commission_rate_2` REAL NOT NULL DEFAULT 0.1,
  `commission_rate_3` REAL NOT NULL DEFAULT 0.04,
  `settlement_day` INTEGER NOT NULL DEFAULT 10,
  `after_sale_days` INTEGER NOT NULL DEFAULT 7,
  `reward_rules_text` TEXT,
  `public_slogans_text` TEXT,
  `updated_at` INTEGER DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS `user_affiliate_stats` (
  `user_id` INTEGER NOT NULL PRIMARY KEY,
  `downline_pv_total` REAL NOT NULL DEFAULT 0,
  `updated_at` INTEGER DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS `commission_records` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `order_id` INTEGER NOT NULL,
  `user_id` INTEGER NOT NULL,
  `tier` INTEGER NOT NULL,
  `goods_base` REAL NOT NULL DEFAULT 0,
  `rate` REAL NOT NULL DEFAULT 0,
  `amount` REAL NOT NULL DEFAULT 0,
  `status` TEXT NOT NULL DEFAULT 'pending',
  `unlock_at` INTEGER NOT NULL DEFAULT 0,
  `settled_period` TEXT DEFAULT NULL,
  `created_at` INTEGER DEFAULT NULL
);

CREATE INDEX IF NOT EXISTS `idx_cr_user` ON `commission_records` (`user_id`);
CREATE INDEX IF NOT EXISTS `idx_cr_order` ON `commission_records` (`order_id`);
CREATE INDEX IF NOT EXISTS `idx_cr_status` ON `commission_records` (`status`);

CREATE TABLE IF NOT EXISTS `gcash_platform_accounts` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `slot` INTEGER NOT NULL DEFAULT 1,
  `label` TEXT NOT NULL DEFAULT '',
  `account_name` TEXT DEFAULT NULL,
  `mobile` TEXT DEFAULT NULL,
  `qr_image` TEXT DEFAULT NULL,
  `is_active` INTEGER NOT NULL DEFAULT 1,
  `sort_order` INTEGER NOT NULL DEFAULT 0,
  `created_at` INTEGER DEFAULT NULL,
  `updated_at` INTEGER DEFAULT NULL,
  UNIQUE (`slot`)
);

CREATE TABLE IF NOT EXISTS `withdrawal_requests` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `user_id` INTEGER NOT NULL,
  `amount` REAL NOT NULL,
  `gcash_number` TEXT NOT NULL,
  `gcash_name` TEXT NOT NULL,
  `status` TEXT NOT NULL DEFAULT 'pending',
  `admin_note` TEXT DEFAULT NULL,
  `payout_ref` TEXT DEFAULT NULL,
  `processed_at` INTEGER DEFAULT NULL,
  `created_at` INTEGER DEFAULT NULL,
  `updated_at` INTEGER DEFAULT NULL,
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS `idx_withdrawal_user` ON `withdrawal_requests`(`user_id`);
CREATE INDEX IF NOT EXISTS `idx_withdrawal_status` ON `withdrawal_requests`(`status`);

CREATE TABLE IF NOT EXISTS `admin_users` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `username` TEXT NOT NULL UNIQUE,
  `password` TEXT NOT NULL,
  `nickname` TEXT DEFAULT NULL,
  `role` TEXT DEFAULT 'admin',
  `avatar` TEXT DEFAULT NULL,
  `status` INTEGER DEFAULT 1,
  `last_login_at` INTEGER DEFAULT NULL,
  `created_at` INTEGER DEFAULT NULL,
  `updated_at` INTEGER DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS `admin_logs` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `admin_id` INTEGER NOT NULL,
  `action` TEXT NOT NULL,
  `target` TEXT DEFAULT NULL,
  `detail` TEXT DEFAULT NULL,
  `ip` TEXT DEFAULT NULL,
  `created_at` INTEGER DEFAULT NULL
);

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

CREATE TABLE IF NOT EXISTS `user_logs` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `user_id` INTEGER NOT NULL,
  `action` TEXT NOT NULL,
  `detail` TEXT DEFAULT NULL,
  `ip` TEXT DEFAULT NULL,
  `created_at` INTEGER DEFAULT NULL,
  `updated_at` INTEGER DEFAULT NULL
);

INSERT OR IGNORE INTO `affiliate_program_config` (`id`, `currency_suffix`, `level1_name`, `level2_name`, `level3_name`,
  `level1_spend_threshold`, `level1_any_order`, `level2_direct_l1_min`, `level2_team_pv`,
  `level3_direct_l2_min`, `level3_team_pv`, `commission_rate_1`, `commission_rate_2`, `commission_rate_3`,
  `settlement_day`, `after_sale_days`, `reward_rules_text`, `public_slogans_text`, `updated_at`)
VALUES (1, 'P', '美妆分享官', '美妆达人', '美妆合伙人',
  1000, 1, 5, 5000, 3, 20000, 0.2, 0.1, 0.04, 10, 7,
  '自用省钱，分享赚钱',
  '美妆自用省钱，分享赚钱',
  strftime('%s','now'));

INSERT OR IGNORE INTO `gcash_platform_accounts` (`slot`, `label`, `is_active`, `sort_order`, `created_at`, `updated_at`) VALUES
(1, 'GCash Account 1', 1, 1, strftime('%s','now'), strftime('%s','now')),
(2, 'GCash Account 2', 1, 2, strftime('%s','now'), strftime('%s','now'));
