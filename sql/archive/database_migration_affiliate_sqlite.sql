-- 分销/邀请体系（SQLite）。备份后执行；若列已存在会报错，可忽略对应语句。

PRAGMA foreign_keys = OFF;

ALTER TABLE `users` ADD COLUMN `invite_code` TEXT DEFAULT NULL;
ALTER TABLE `users` ADD COLUMN `parent_id` INTEGER DEFAULT NULL;
ALTER TABLE `users` ADD COLUMN `affiliate_level` INTEGER NOT NULL DEFAULT 0;
ALTER TABLE `users` ADD COLUMN `total_paid_goods` REAL NOT NULL DEFAULT 0;

CREATE UNIQUE INDEX IF NOT EXISTS `uk_users_invite_code` ON `users` (`invite_code`);
CREATE INDEX IF NOT EXISTS `idx_users_parent` ON `users` (`parent_id`);

ALTER TABLE `orders` ADD COLUMN `remark` TEXT DEFAULT NULL;
ALTER TABLE `orders` ADD COLUMN `goods_amount` REAL NOT NULL DEFAULT 0;
ALTER TABLE `orders` ADD COLUMN `paid_at` INTEGER DEFAULT NULL;
ALTER TABLE `orders` ADD COLUMN `confirmed_at` INTEGER DEFAULT NULL;
ALTER TABLE `orders` ADD COLUMN `b1_user_id` INTEGER DEFAULT NULL;
ALTER TABLE `orders` ADD COLUMN `b2_user_id` INTEGER DEFAULT NULL;
ALTER TABLE `orders` ADD COLUMN `b3_user_id` INTEGER DEFAULT NULL;

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

INSERT OR IGNORE INTO `affiliate_program_config` (`id`, `currency_suffix`, `level1_name`, `level2_name`, `level3_name`,
  `level1_spend_threshold`, `level1_any_order`, `level2_direct_l1_min`, `level2_team_pv`,
  `level3_direct_l2_min`, `level3_team_pv`, `commission_rate_1`, `commission_rate_2`, `commission_rate_3`,
  `settlement_day`, `after_sale_days`, `reward_rules_text`, `public_slogans_text`, `updated_at`)
VALUES (1, 'P', '美妆分享官', '美妆达人', '美妆合伙人',
  1000, 1, 5, 5000, 3, 20000, 0.2, 0.1, 0.04, 10, 7,
  '自用省钱，分享赚钱
• 你推荐朋友买 → 你拿一级佣金
• 朋友再推荐别人买 → 你拿二级佣金
• 朋友的下级再推荐买 → 你拿三级佣金',
  '美妆自用省钱，分享赚钱
三级分销，真实卖货拿佣金
无加盟费、无囤货、无压力
卖产品都能赚，分享就能变现',
  strftime('%s','now'));

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

PRAGMA foreign_keys = ON;
