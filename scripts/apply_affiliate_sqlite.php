<?php
/**
 * 应用分销相关 SQLite 迁移（可重复执行，已存在列/表会跳过）
 * 用法：php scripts/apply_affiliate_sqlite.php
 */
declare(strict_types=1);

$root = dirname(__DIR__);
$dbFile = $root . DIRECTORY_SEPARATOR . 'database.sqlite';
if (!is_file($dbFile)) {
    fwrite(STDERR, "database.sqlite not found at {$dbFile}\n");
    exit(1);
}

$pdo = new PDO('sqlite:' . $dbFile);
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

$sqlFile = $root . DIRECTORY_SEPARATOR . 'sql' . DIRECTORY_SEPARATOR . 'sqlite' . DIRECTORY_SEPARATOR . 'migrations' . DIRECTORY_SEPARATOR . '007_affiliate.sql';
if (!is_file($sqlFile)) {
    fwrite(STDERR, "Migration file missing\n");
    exit(1);
}

$sql = file_get_contents($sqlFile);
$statements = array_filter(array_map('trim', preg_split('/;\s*\n/', $sql)));

foreach ($statements as $stmt) {
    if ($stmt === '' || str_starts_with($stmt, '--')) {
        continue;
    }
    try {
        $pdo->exec($stmt);
        echo "OK: " . substr(str_replace(["\r", "\n"], ' ', $stmt), 0, 72) . "…\n";
    } catch (PDOException $e) {
        $msg = $e->getMessage();
        if (str_contains($msg, 'duplicate column') || str_contains($msg, 'already exists')) {
            echo "SKIP: {$msg}\n";
            continue;
        }
        fwrite(STDERR, "FAIL: {$stmt}\n  {$msg}\n");
    }
}

echo "Done.\n";
