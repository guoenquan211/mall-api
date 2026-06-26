-- 创建/重置管理员：admin / As741293@123
-- 在宝塔 → 数据库 → 选中库 → 执行本 SQL

SET NAMES utf8mb4;

INSERT INTO `admin_users` (`username`, `password`, `nickname`, `role`, `status`, `created_at`, `updated_at`)
VALUES (
  'admin',
  '$2b$10$8Ar.tYBg727J8cXnA2I19OCedEGoc9o17.s0X.tY2Xsw6N.RGNFbS',
  '超级管理员',
  'super_admin',
  1,
  UNIX_TIMESTAMP(),
  UNIX_TIMESTAMP()
)
ON DUPLICATE KEY UPDATE
  `password`   = VALUES(`password`),
  `nickname`   = VALUES(`nickname`),
  `role`       = VALUES(`role`),
  `status`     = 1,
  `updated_at` = UNIX_TIMESTAMP();
