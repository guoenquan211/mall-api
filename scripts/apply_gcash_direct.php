<?php
/** 直接用 PDO 应用 GCash 迁移（不依赖 ThinkPHP 连接） */
declare(strict_types=1);

$dbFile = dirname(__DIR__) . DIRECTORY_SEPARATOR . 'database.sqlite';
if (!is_file($dbFile)) {
    fwrite(STDERR, "Database not found: {$dbFile}\n");
    exit(1);
}

$pdo = new PDO('sqlite:' . $dbFile);
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

$sqlFile = dirname(__DIR__) . '/database_migration_gcash_sqlite.sql';
$raw = file_get_contents($sqlFile);
$statements = array_filter(array_map('trim', preg_split('/;\s*\n/', $raw)));

foreach ($statements as $stmt) {
    if ($stmt === '' || str_starts_with($stmt, '--')) {
        continue;
    }
    try {
        $pdo->exec($stmt);
        echo 'OK: ' . substr(str_replace("\n", ' ', $stmt), 0, 70) . "\n";
    } catch (Throwable $e) {
        echo 'SKIP: ' . $e->getMessage() . "\n";
    }
}

$orderCols = [
    'payment_method'       => "TEXT NOT NULL DEFAULT 'gcash'",
    'payment_status'       => "TEXT NOT NULL DEFAULT 'pending'",
    'payment_account_slot' => 'INTEGER DEFAULT NULL',
    'user_paid_at'         => 'INTEGER DEFAULT NULL',
    'payment_remark'       => 'TEXT DEFAULT NULL',
    'payment_proof_image'  => 'TEXT DEFAULT NULL',
    'payment_reject_reason'=> 'TEXT DEFAULT NULL',
];
foreach ($orderCols as $col => $def) {
    try {
        $pdo->exec("ALTER TABLE orders ADD COLUMN {$col} {$def}");
        echo "OK: orders.{$col}\n";
    } catch (Throwable $e) {
        echo "SKIP orders.{$col}: {$e->getMessage()}\n";
    }
}

foreach (['gcash_number' => 'TEXT DEFAULT NULL', 'gcash_name' => 'TEXT DEFAULT NULL'] as $col => $def) {
    try {
        $pdo->exec("ALTER TABLE users ADD COLUMN {$col} {$def}");
        echo "OK: users.{$col}\n";
    } catch (Throwable $e) {
        echo "SKIP users.{$col}: {$e->getMessage()}\n";
    }
}

$pdo->exec(<<<'SQL'
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
)
SQL);

$count = (int) $pdo->query('SELECT COUNT(*) FROM gcash_platform_accounts')->fetchColumn();
if ($count === 0) {
    $now = time();
    $pdo->exec(
        "INSERT INTO gcash_platform_accounts (slot, label, is_active, sort_order, created_at, updated_at) VALUES "
        . "(1, 'GCash Account 1', 1, 1, {$now}, {$now}), "
        . "(2, 'GCash Account 2', 1, 2, {$now}, {$now})"
    );
    echo "OK: seeded gcash_platform_accounts\n";
}

// 回填缺失的下单时间（从订单号 ORD + YmdHis 解析）
$rows = $pdo->query("SELECT id, order_no, created_at FROM orders WHERE created_at IS NULL OR created_at = '' OR created_at = 0")->fetchAll(PDO::FETCH_ASSOC);
foreach ($rows as $row) {
    $ts = null;
    if (preg_match('/ORD(\d{14})/', (string) $row['order_no'], $m)) {
        $dt = \DateTime::createFromFormat('YmdHis', $m[1]);
        if ($dt) {
            $ts = $dt->getTimestamp();
        }
    }
    if (!$ts) {
        $ts = time();
    }
    $stmt = $pdo->prepare('UPDATE orders SET created_at = ? WHERE id = ?');
    $stmt->execute([$ts, $row['id']]);
}
if ($rows) {
    echo 'OK: backfilled created_at for ' . count($rows) . " orders\n";
}

echo "Done.\n";
