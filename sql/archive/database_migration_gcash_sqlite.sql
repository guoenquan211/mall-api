-- GCash 收款与佣金提现（SQLite）
-- 执行: php scripts/apply_gcash_sqlite.php

CREATE TABLE IF NOT EXISTS gcash_platform_accounts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  slot INTEGER NOT NULL DEFAULT 1,
  label TEXT NOT NULL DEFAULT '',
  account_name TEXT DEFAULT NULL,
  mobile TEXT DEFAULT NULL,
  qr_image TEXT DEFAULT NULL,
  is_active INTEGER NOT NULL DEFAULT 1,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER DEFAULT NULL,
  updated_at INTEGER DEFAULT NULL,
  UNIQUE (slot)
);

CREATE TABLE IF NOT EXISTS withdrawal_requests (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  amount REAL NOT NULL,
  gcash_number TEXT NOT NULL,
  gcash_name TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  admin_note TEXT DEFAULT NULL,
  payout_ref TEXT DEFAULT NULL,
  processed_at INTEGER DEFAULT NULL,
  created_at INTEGER DEFAULT NULL,
  updated_at INTEGER DEFAULT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_withdrawal_user ON withdrawal_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_withdrawal_status ON withdrawal_requests(status);

-- orders 扩展（若列已存在会由 apply 脚本跳过）
-- payment_status: pending | user_confirmed | approved | rejected
-- payment_method: gcash
