<?php
$root = dirname(__DIR__);
$sqlFile = $root . DIRECTORY_SEPARATOR . 'database_migration_users_locale_sqlite.sql';
$dbs = ['database.sqlite', 'database_1.sqlite'];
if (!is_file($sqlFile)) {
    fwrite(STDERR, "Missing: {$sqlFile}\n");
    exit(1);
}
$sql = trim(file_get_contents($sqlFile));
foreach ($dbs as $name) {
    $dbPath = $root . DIRECTORY_SEPARATOR . $name;
    if (!is_file($dbPath)) {
        continue;
    }
    $pdo = new PDO('sqlite:' . $dbPath, null, null, [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
    try {
        $pdo->exec($sql);
        echo "OK: users.locale applied to {$name}\n";
    } catch (PDOException $e) {
        if (stripos($e->getMessage(), 'duplicate column') !== false) {
            echo "Skip (exists): {$name}\n";
            continue;
        }
        throw $e;
    }
}
