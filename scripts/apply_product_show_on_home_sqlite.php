<?php
/**
 * One-shot: add products.show_on_home to existing SQLite DBs (local dev).
 */
$root = dirname(__DIR__);
$sqlFile = $root . DIRECTORY_SEPARATOR . 'database_migration_product_show_on_home_sqlite.sql';

$dbs = ['database.sqlite', 'database_1.sqlite'];
if (!is_file($sqlFile)) {
    fwrite(STDERR, "Missing migration file: {$sqlFile}\n");
    exit(1);
}

$sql = file_get_contents($sqlFile);
$sql = preg_replace('/^\s*--.*$/m', '', $sql);
$parts = array_filter(array_map('trim', explode(';', $sql)));

foreach ($dbs as $name) {
    $dbPath = $root . DIRECTORY_SEPARATOR . $name;
    if (!is_file($dbPath)) {
        continue;
    }
    $pdo = new PDO('sqlite:' . $dbPath, null, null, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    ]);
    foreach ($parts as $stmt) {
        if ($stmt === '') {
            continue;
        }
        try {
            $pdo->exec($stmt);
        } catch (PDOException $e) {
            if (stripos($e->getMessage(), 'duplicate column') !== false) {
                echo "Skip (already exists): {$name}\n";
                continue;
            }
            throw $e;
        }
    }
    echo "OK: show_on_home applied to {$name}\n";
}
