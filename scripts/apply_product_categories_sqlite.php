<?php
/**
 * One-shot: ensure product_categories exists in SQLite (local dev).
 */
$root = dirname(__DIR__);
$sqlFile = $root . DIRECTORY_SEPARATOR . 'database_migration_product_categories_sqlite.sql';

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
        $pdo->exec($stmt);
    }
    echo "OK: product_categories applied to {$name}\n";
}
