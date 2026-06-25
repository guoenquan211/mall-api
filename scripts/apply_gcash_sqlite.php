<?php
/**
 * 应用 GCash / 提现相关表结构到 SQLite
 * 用法: cd backend && php scripts/apply_gcash_sqlite.php
 */
declare(strict_types=1);

// ThinkPHP CLI 下 Db 可能连不上，统一走直连 SQLite
require __DIR__ . '/apply_gcash_direct.php';
return;

$root = dirname(__DIR__);
require $root . '/vendor/autoload.php';

$app = new think\App();
$app->initialize();

$pdo = \think\facade\Db::connect()->getPdo();

$sqlFile = $root . '/sql/sqlite/migrations/008_gcash.sql';
if (!is_file($sqlFile)) {
    fwrite(STDERR, "Missing {$sqlFile}\n");
    exit(1);
}

$raw = file_get_contents($sqlFile);
$statements = array_filter(array_map('trim', preg_split('/;\s*\n/', $raw)));

foreach ($statements as $stmt) {
    if ($stmt === '' || str_starts_with($stmt, '--')) {
        continue;
    }
    try {
        $pdo->exec($stmt);
        echo "OK: " . substr(str_replace("\n", ' ', $stmt), 0, 80) . "...\n";
    } catch (Throwable $e) {
        echo "SKIP/ERR: {$e->getMessage()}\n";
    }
}

$orderCols = [
    'payment_method'   => "TEXT NOT NULL DEFAULT 'gcash'",
    'payment_status'   => "TEXT NOT NULL DEFAULT 'pending'",
    'payment_account_slot' => 'INTEGER DEFAULT NULL',
    'user_paid_at'     => 'INTEGER DEFAULT NULL',
    'payment_remark'   => 'TEXT DEFAULT NULL',
];

foreach ($orderCols as $col => $def) {
  try {
    $pdo->exec("ALTER TABLE orders ADD COLUMN {$col} {$def}");
    echo "OK: orders.{$col}\n";
  } catch (Throwable $e) {
    echo "SKIP orders.{$col}: {$e->getMessage()}\n";
  }
}

$userCols = [
    'gcash_number' => 'TEXT DEFAULT NULL',
    'gcash_name'   => 'TEXT DEFAULT NULL',
];

foreach ($userCols as $col => $def) {
  try {
    $pdo->exec("ALTER TABLE users ADD COLUMN {$col} {$def}");
    echo "OK: users.{$col}\n";
  } catch (Throwable $e) {
    echo "SKIP users.{$col}: {$e->getMessage()}\n";
  }
}

// 默认两个收款账号槽位
$count = (int) $pdo->query('SELECT COUNT(*) FROM gcash_platform_accounts')->fetchColumn();
if ($count === 0) {
    $now = time();
    $pdo->exec("INSERT INTO gcash_platform_accounts (slot, label, is_active, sort_order, created_at, updated_at) VALUES
        (1, 'GCash 账号 1', 1, 1, {$now}, {$now}),
        (2, 'GCash 账号 2', 1, 2, {$now}, {$now})");
    echo "OK: seeded gcash_platform_accounts\n";
}

echo "Done.\n";
